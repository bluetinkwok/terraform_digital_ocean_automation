# Create a new SSH key
resource "digitalocean_ssh_key" "default" {
  name       = "terraform-n8n-flowise"
  public_key = file("${path.module}/.ssh/do_n8n_flowise.pub")
}

# Create VPC for our applications
resource "digitalocean_vpc" "app_vpc" {
  name     = "app-network"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# Create combined droplet for both applications
resource "digitalocean_droplet" "apps" {
  image    = "docker-20-04"
  name     = "n8n-flowise-apps"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.app_vpc.id
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  # Wait for the droplet to be fully provisioned before transferring files
  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file("${path.module}/.ssh/do_n8n_flowise")
    timeout     = "5m"  # Increased timeout for slower connections
  }

  # First create the necessary directories
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/apps",
      "mkdir -p /opt/logs"
    ]
  }

  # Upload all the scripts
  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/opt/apps/"
  }

  # Set execution permissions for scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/apps/*.sh",
      "echo 'Set execution permissions for all scripts'"
    ]
  }

  # Execute the main init script with environment variables and capture output
  provisioner "remote-exec" {
    inline = [
      "cd /opt/apps",
      "export DEBIAN_FRONTEND=noninteractive",
      "export n8n_username='${var.n8n_username}'",
      "export n8n_password='${var.n8n_password}'",
      "export n8n_domain='n8n.${var.domain}'",
      "export flowise_username='${var.flowise_username}'",
      "export flowise_password='${var.flowise_password}'",
      "export flowise_domain='flowise.${var.domain}'",
      "export email='${var.email}'",
      "export enable_backups='${var.enable_backups}'",
      "export backup_time='${var.backup_time}'",
      "export backup_retention_days='${var.backup_retention_days}'",
      "echo 'Starting initialization script...'",
      "bash init.sh || { echo 'Initialization failed. Checking logs...'; cat /root/setup.log; exit 1; }",
      "echo 'Initialization completed successfully'",
      "docker ps",
      "echo 'Installation verified - showing running containers'"
    ]
    on_failure = continue  # Continue on failure so we can see logs
  }
  
  # Upload the setup logs for troubleshooting if needed
  provisioner "local-exec" {
    command = "mkdir -p logs && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i .ssh/do_n8n_flowise root@${self.ipv4_address} 'cat /root/setup.log' > logs/setup-${self.id}.log || echo 'Could not retrieve logs'"
  }
} 
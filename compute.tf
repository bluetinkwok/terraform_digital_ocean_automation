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
  }

  # First create the necessary directories
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/apps"
    ]
  }

  # Upload all the scripts
  provisioner "file" {
    source      = "${path.module}/scripts/init.sh"
    destination = "/opt/apps/init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/n8n-init.sh"
    destination = "/opt/apps/n8n-init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/flowise-init.sh"
    destination = "/opt/apps/flowise-init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/backup.sh"
    destination = "/opt/apps/backup.sh"
  }

  # Set execution permissions for scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/apps/init.sh",
      "chmod +x /opt/apps/n8n-init.sh",
      "chmod +x /opt/apps/flowise-init.sh",
      "chmod +x /opt/apps/backup.sh"
    ]
  }

  # Execute the main init script with environment variables
  provisioner "remote-exec" {
    inline = [
      "cd /opt/apps",
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
      "./init.sh"
    ]
  }
} 
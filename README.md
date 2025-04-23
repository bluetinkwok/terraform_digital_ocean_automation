# Terraform DigitalOcean n8n and Flowise Setup

This Terraform configuration sets up n8n and Flowise applications on a single DigitalOcean droplet with automatic SSL certificate management using Caddy as a reverse proxy.

## Architecture

- **Single Droplet**: Both n8n and Flowise run on one DigitalOcean droplet to optimize costs
- **Docker Compose**: Each application runs in its own Docker Compose setup
- **Centralized Caddy**: A single Caddy instance handles SSL/TLS certificates and reverse proxy for both applications
- **DNS Management**: Automatically configures DNS records in both DigitalOcean and Cloudflare
- **Optional Backups**: Automated daily backups of application data and volumes
- **Remote State Storage**: Terraform state stored in Cloudflare R2 for better collaboration and state management

## Project Structure

The Terraform configuration is organized into multiple files for better maintainability:

- **main.tf**: Entry point and overview
- **providers.tf**: Provider configurations and backend setup
- **compute.tf**: Compute resources (SSH keys, VPC, droplets)
- **dns.tf**: DNS configuration for both Cloudflare and DigitalOcean
- **security.tf**: Firewall and security configurations
- **variables.tf**: Input variable definitions
- **outputs.tf**: Output values
- **terraform.tfvars.example**: Example variable values

## Prerequisites

1. DigitalOcean account and API token
2. Cloudflare account, API token, and Zone ID
3. Terraform installed on your local machine
4. SSH key pair (we'll create a project-specific one in the `.ssh` folder)
5. Domain name registered and added to Cloudflare

## Generating SSH Keys

You should create a project-specific SSH key pair for this deployment:

### For Linux/macOS:

```bash
# Make sure the project .ssh directory exists
mkdir -p .ssh

# Generate a new SSH key pair with a unique name
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f .ssh/do_n8n_flowise

# Enter a secure passphrase (or leave empty for no passphrase)

# Verify the key was created
ls -la .ssh/do_n8n_flowise.pub
```

### For Windows (using Git Bash or similar):

```bash
# Make sure the project .ssh directory exists
mkdir -p .ssh

# Generate a new SSH key pair with a unique name
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f .ssh/do_n8n_flowise

# Enter a secure passphrase (or leave empty for no passphrase)

# Verify the key was created
ls -la .ssh/do_n8n_flowise.pub
```

### Alternative for Windows (using PuTTYgen):

1. Download and install PuTTY which includes PuTTYgen
2. Create a `.ssh` folder in your project directory
3. Open PuTTYgen and click "Generate"
4. Move your mouse around to generate randomness
5. Set a passphrase (optional but recommended)
6. Click "Save private key" and save it as `.ssh/do_n8n_flowise.ppk`
7. Export and save the public key in OpenSSH format as `.ssh/do_n8n_flowise.pub`

**Important**: After generating the key, remember to:
1. Keep your private key secure
2. Never share your private key with anyone
3. Use a strong passphrase if possible

## Update main.tf Configuration

The `main.tf` file is already configured to use the local SSH key:

```hcl
# In main.tf:
public_key = file("${path.module}/.ssh/do_n8n_flowise.pub")

# Connection block:
connection {
  type        = "ssh"
  user        = "root"
  host        = self.ipv4_address
  private_key = file("${path.module}/.ssh/do_n8n_flowise")
}
```

## Setup Instructions

1. Clone this repository:
```bash
git clone <repository-url>
cd terraform-digital-ocean
```

2. Create a `terraform.tfvars` file from the example:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars` with your values:
- Set your domain name
- Set your email address for SSL certificates
- Configure usernames and passwords for n8n and Flowise
- Configure backup settings (enable/disable, schedule, retention)
- Add your Cloudflare API token and Zone ID
- Adjust region and droplet size if needed

4. Set your DigitalOcean API token:
```bash
export DIGITALOCEAN_TOKEN=your_token_here
```

5. Configure Cloudflare R2 Backend:
   
   Create a `terraform.tfbackend` file with your Cloudflare R2 credentials:
   
   ```
   # Required parameters
   access_key = "YOUR_R2_ACCESS_KEY"
   secret_key = "YOUR_R2_SECRET_KEY"
   endpoints = {
     s3 = "https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com"
   }
   bucket     = "terraform-state"
   key        = "terraform.tfstate"
   region     = "auto"
   force_path_style = true
   ```
   
   Replace the placeholders with your actual Cloudflare R2 credentials:
   - YOUR_R2_ACCESS_KEY: Your Cloudflare R2 access key
   - YOUR_R2_SECRET_KEY: Your Cloudflare R2 secret key
   - YOUR_ACCOUNT_ID: Your Cloudflare account ID
   
   Note: Make sure you've created a bucket named `terraform-state` (or whatever name you specify in the bucket parameter) in your Cloudflare R2 account before initializing.
   
   The backend configuration is split between:
   - `main.tf`: Contains non-sensitive backend settings (like validation skipping and skip_requesting_account_id)
   - `terraform.tfbackend`: Contains all sensitive credentials and variable settings

6. Initialize Terraform with the R2 backend:
   ```bash
   terraform init -backend-config=terraform.tfbackend
   ```
   
   Note: If you didn't create a terraform.tfbackend file with all required parameters, Terraform will prompt you for the missing values (bucket, key, region, etc.) during initialization.

7. Review the planned changes:
```bash
terraform plan
```

8. Apply the configuration:
```bash
terraform apply
```

## What Gets Created

- One DigitalOcean droplet running both n8n and Flowise
- VPC network for the application
- DNS A records for n8n.yourdomain.com and flowise.yourdomain.com
- Firewall rules for HTTP, HTTPS, and SSH
- Docker volumes for persistent storage
- Centralized Caddy reverse proxy with automatic SSL for both applications
- Optional daily backup system for application data

## Accessing the Applications

After the deployment is complete:

- n8n will be available at: https://n8n.yourdomain.com
- Flowise will be available at: https://flowise.yourdomain.com

Where `yourdomain.com` is the domain you specified in your terraform.tfvars file.

## Application Details

### n8n
- Running on internal port 5678
- Authentication enabled with credentials from terraform.tfvars
- Data persisted in Docker volume

### Flowise
- Running on internal port 3000
- Authentication enabled with credentials from terraform.tfvars
- Data persisted in Docker volume

### Caddy
- Running in host network mode
- Automatically obtains and renews SSL certificates
- Proxies requests to the appropriate application based on domain

### Backup System (Optional)
- Daily backups of both applications' data and Docker volumes
- Configurable backup timing via cron expression
- Configurable retention period for old backups
- Can be enabled/disabled via terraform.tfvars

## Backup Details

The backup system, when enabled:

1. Creates backup archives of:
   - n8n file data from /opt/apps/n8n/data
   - n8n database from the Docker volume
   - Flowise file data from /opt/apps/flowise/data
   - Flowise database from the Docker volume

2. Stores backups in `/opt/backups` with subdirectories for each application

3. Automatically removes backups older than the specified retention period

4. Logs all backup operations to `/opt/backups/backup.log`

### Backup Configuration

In your `terraform.tfvars` file:

```
# Enable or disable backups
enable_backups = true

# When to run backups (in cron format)
backup_time = "0 2 * * *"  # 2 AM daily

# Number of days to keep backups
backup_retention_days = 7
```

### Accessing Backups

You can access the backups via SSH:
```bash
ssh root@<droplet-ip>
ls -la /opt/backups/{n8n,flowise}
```

### Restoring from Backup

To restore n8n data:
```bash
ssh root@<droplet-ip>
cd /opt/apps/n8n
docker-compose stop n8n
tar -xzf /opt/backups/n8n/n8n-data-YYYY-MM-DD-HHMM.tar.gz -C /opt/apps/n8n
docker run --rm -v n8n_data:/target -v /opt/backups/n8n:/backup ubuntu bash -c "rm -rf /target/* && tar -xzf /backup/n8n-volume-YYYY-MM-DD-HHMM.tar.gz -C /target"
docker-compose start n8n
```

To restore Flowise data:
```bash
ssh root@<droplet-ip>
cd /opt/apps/flowise
docker-compose stop flowise
tar -xzf /opt/backups/flowise/flowise-data-YYYY-MM-DD-HHMM.tar.gz -C /opt/apps/flowise
docker run --rm -v flowise_data:/target -v /opt/backups/flowise:/backup ubuntu bash -c "rm -rf /target/* && tar -xzf /backup/flowise-volume-YYYY-MM-DD-HHMM.tar.gz -C /target"
docker-compose start flowise
```

## Maintenance

### To update n8n:
```bash
ssh root@<droplet-ip>
cd /opt/apps/n8n
docker-compose pull
docker-compose up -d
```

### To update Flowise:
```bash
ssh root@<droplet-ip>
cd /opt/apps/flowise
docker-compose pull
docker-compose up -d
```

### To update Caddy:
```bash
ssh root@<droplet-ip>
cd /opt/apps/caddy
docker-compose pull
docker-compose up -d
```

### To manually run a backup:
```bash
ssh root@<droplet-ip>
/opt/apps/backup.sh
```

## Troubleshooting

- Check Caddy logs: `docker logs -f $(docker ps -q -f name=caddy)`
- Check n8n logs: `docker logs -f $(docker ps -q -f name=n8n)`
- Check Flowise logs: `docker logs -f $(docker ps -q -f name=flowise)`
- Check backup logs: `cat /opt/backups/backup.log`
- Restart all services: `cd /opt/apps && ./init.sh`

## Cleanup

To destroy all created resources:
```bash
terraform destroy
```

## Security Notes

- The configuration uses Caddy for automatic SSL certificate management
- Basic authentication is enabled for both applications
- Firewall rules are configured to allow only necessary ports
- All sensitive variables are marked as sensitive in Terraform
- Each application runs in an isolated Docker Compose environment 
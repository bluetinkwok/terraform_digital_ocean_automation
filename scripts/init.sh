#!/bin/bash
set -e  # Exit on error

# Setup logging
LOG_FILE="/root/setup.log"
exec > >(tee -a ${LOG_FILE}) 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting installation process..."

# Update system and install dependencies
echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating system packages..."
apt-get update -y || { echo "Failed to update apt packages"; exit 1; }

echo "$(date '+%Y-%m-%d %H:%M:%S') - Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y git curl || { echo "Failed to install git and curl"; exit 1; }

# Install Docker using the official install script instead of apt
echo "$(date '+%Y-%m-%d %H:%M:%S') - Installing Docker using official script..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh || { echo "Failed to install Docker"; exit 1; }

# Install Docker Compose
echo "$(date '+%Y-%m-%d %H:%M:%S') - Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose || { echo "Failed to install Docker Compose"; exit 1; }

# Verify Docker installation
echo "$(date '+%Y-%m-%d %H:%M:%S') - Verifying installations..."
docker --version || { echo "Docker installation failed"; exit 1; }
docker-compose --version || { echo "Docker-compose installation failed"; exit 1; }

# Start Docker service
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Docker service..."
systemctl start docker
systemctl enable docker
systemctl status docker --no-pager || { echo "Docker service failed to start"; exit 1; }

# Wait for Docker to be fully ready
echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for Docker service to be ready..."
sleep 5

# Test Docker functionality
echo "$(date '+%Y-%m-%d %H:%M:%S') - Testing Docker functionality..."
docker run --rm hello-world || { echo "Docker test failed"; exit 1; }

# Create base directories
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating directories..."
mkdir -p /opt/apps/{n8n,flowise}/{caddy_config,data}
mkdir -p /opt/apps/caddy/config

# Create a central Caddy configuration
echo "$(date '+%Y-%m-%d %H:%M:%S') - Configuring Caddy..."
cat > /opt/apps/caddy/Caddyfile << EOL
${n8n_domain} {
    reverse_proxy 127.0.0.1:5678 {
        flush_interval -1
    }
}

${flowise_domain} {
    reverse_proxy 127.0.0.1:3000 {
        flush_interval -1
    }
}
EOL

# Create docker-compose.yml for Caddy
cat > /opt/apps/caddy/docker-compose.yml << EOL
version: "3.7"

services:
  caddy:
    image: caddy
    restart: always
    network_mode: "host"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./config:/data
    environment:
      - EMAIL=${email}

EOL

# Export environment variables for the application scripts
echo "$(date '+%Y-%m-%d %H:%M:%S') - Setting up environment variables..."
export N8N_USERNAME="${n8n_username}"
export N8N_PASSWORD="${n8n_password}"
export N8N_DOMAIN="${n8n_domain}"
export FLOWISE_USERNAME="${flowise_username}"
export FLOWISE_PASSWORD="${flowise_password}"
export FLOWISE_DOMAIN="${flowise_domain}"
export EMAIL="${email}"

# Print out environment variables for debugging (mask passwords)
echo "$(date '+%Y-%m-%d %H:%M:%S') - Environment variables:"
echo "N8N_USERNAME: ${N8N_USERNAME}"
echo "N8N_DOMAIN: ${N8N_DOMAIN}"
echo "FLOWISE_USERNAME: ${FLOWISE_USERNAME}"
echo "FLOWISE_DOMAIN: ${FLOWISE_DOMAIN}"
echo "EMAIL: ${EMAIL}"

# Pull Docker images in advance to avoid timeouts
echo "$(date '+%Y-%m-%d %H:%M:%S') - Pulling required Docker images..."
docker pull n8nio/n8n || { echo "Failed to pull n8n image"; exit 1; }
docker pull flowiseai/flowise || { echo "Failed to pull flowise image"; exit 1; }
docker pull caddy || { echo "Failed to pull caddy image"; exit 1; }

# Run n8n setup
echo "$(date '+%Y-%m-%d %H:%M:%S') - Setting up n8n..."
cd /opt/apps/n8n
bash /opt/apps/n8n-init.sh || { echo "n8n setup failed"; exit 1; }

# Verify n8n is running
echo "$(date '+%Y-%m-%d %H:%M:%S') - Verifying n8n..."
sleep 10  # Give container time to start
docker ps | grep n8n || { echo "n8n container not running"; exit 1; }

# Run flowise setup
echo "$(date '+%Y-%m-%d %H:%M:%S') - Setting up Flowise..."
cd /opt/apps/flowise
bash /opt/apps/flowise-init.sh || { echo "Flowise setup failed"; exit 1; }

# Verify flowise is running
echo "$(date '+%Y-%m-%d %H:%M:%S') - Verifying Flowise..."
sleep 10  # Give container time to start
docker ps | grep flowise || { echo "Flowise container not running"; exit 1; }

# Start Caddy after applications are running
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Caddy..."
cd /opt/apps/caddy
docker-compose up -d || { echo "Failed to start Caddy"; exit 1; }

# Verify Caddy is running
echo "$(date '+%Y-%m-%d %H:%M:%S') - Verifying Caddy..."
sleep 10  # Give container time to start
docker ps | grep caddy || { echo "Caddy container not running"; exit 1; }

# Check connectivity to applications
echo "$(date '+%Y-%m-%d %H:%M:%S') - Testing internal connectivity to applications..."
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5678 || echo "Warning: Could not connect to n8n on port 5678"
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 || echo "Warning: Could not connect to Flowise on port 3000"

# Set up backups if enabled
if [ "${enable_backups}" = "true" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Setting up daily backups..."
  
  # Create backup directory
  mkdir -p /opt/backups
  mkdir -p /opt/backups/n8n
  mkdir -p /opt/backups/flowise
  
  # Replace placeholder with actual value in backup script
  sed -i "s/\${BACKUP_RETENTION_DAYS}/${backup_retention_days}/g" /opt/apps/backup.sh
  
  # Add cron job for daily backups
  (crontab -l 2>/dev/null || echo "") | grep -v "/opt/apps/backup.sh" | { cat; echo "${backup_time} /opt/apps/backup.sh >> /opt/backups/backup.log 2>&1"; } | crontab -
  
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup setup complete. Backups will run at ${backup_time} and be kept for ${backup_retention_days} days."
fi

# Configure firewall to allow necessary traffic
echo "$(date '+%Y-%m-%d %H:%M:%S') - Configuring firewall..."
apt-get install -y ufw
ufw allow ssh
ufw allow http
ufw allow https
echo "y" | ufw enable || echo "Warning: Firewall setup failed"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Installation complete! Services running:"
docker ps

echo "$(date '+%Y-%m-%d %H:%M:%S') - URLs:"
echo "n8n: https://${n8n_domain}"
echo "Flowise: https://${flowise_domain}"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Setup log is available at: ${LOG_FILE}"
#!/bin/bash

# Update system and install dependencies
apt-get update
apt-get install -y git docker.io docker-compose

# Start Docker service
systemctl start docker
systemctl enable docker

# Create base directories
mkdir -p /opt/apps/{n8n,flowise}/{caddy_config,data}
mkdir -p /opt/apps/caddy/config

# Create a central Caddy configuration
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
export N8N_USERNAME="${n8n_username}"
export N8N_PASSWORD="${n8n_password}"
export N8N_DOMAIN="${n8n_domain}"
export FLOWISE_USERNAME="${flowise_username}"
export FLOWISE_PASSWORD="${flowise_password}"
export FLOWISE_DOMAIN="${flowise_domain}"
export EMAIL="${email}"

# Run n8n setup
cd /opt/apps/n8n
bash /opt/apps/n8n-init.sh

# Run flowise setup
cd /opt/apps/flowise
bash /opt/apps/flowise-init.sh

# Start Caddy after applications are running
cd /opt/apps/caddy
docker-compose up -d

# Set up backups if enabled
if [ "${enable_backups}" = "true" ]; then
  echo "Setting up daily backups..."
  
  # Create backup directory
  mkdir -p /opt/backups
  mkdir -p /opt/backups/n8n
  mkdir -p /opt/backups/flowise
  
  # Replace placeholder with actual value in backup script
  sed -i "s/\${BACKUP_RETENTION_DAYS}/${backup_retention_days}/g" /opt/apps/backup.sh
  
  # Add cron job for daily backups
  (crontab -l 2>/dev/null || echo "") | grep -v "/opt/apps/backup.sh" | { cat; echo "${backup_time} /opt/apps/backup.sh >> /opt/backups/backup.log 2>&1"; } | crontab -
  
  echo "Backup setup complete. Backups will run at ${backup_time} and be kept for ${backup_retention_days} days."
fi
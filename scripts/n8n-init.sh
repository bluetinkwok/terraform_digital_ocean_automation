#!/bin/bash
set -e  # Exit on error

# Log all output
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting n8n setup..."

# Create Docker volumes for n8n
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating Docker volume for n8n..."
docker volume create n8n_data || { echo "Failed to create n8n_data volume"; exit 1; }

# Configure n8n
echo "$(date '+%Y-%m-%d %H:%M:%S') - Configuring n8n..."
cd /opt/apps/n8n

# Create n8n environment file
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating n8n environment file..."
cat > .env << EOL
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=${N8N_USERNAME}
N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
N8N_HOST=${N8N_DOMAIN}
N8N_PROTOCOL=https
N8N_PORT=5678
N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)
EOL

# Verify the environment file was created
if [ ! -f .env ]; then
  echo "Failed to create n8n .env file"
  exit 1
fi

# Create n8n docker-compose.yml
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating n8n docker-compose file..."
cat > docker-compose.yml << EOL
version: "3.7"

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "127.0.0.1:5678:5678"
    env_file:
      - .env
    environment:
      - N8N_HOST=\${N8N_HOST}
      - NODE_ENV=production
      - WEBHOOK_URL=https://\${N8N_HOST}/
      - GENERIC_TIMEZONE=Asia/Singapore
    volumes:
      - n8n_data:/home/node/.n8n
      - ./data:/files

volumes:
  n8n_data:
    external: true
EOL

# Verify the docker-compose file was created
if [ ! -f docker-compose.yml ]; then
  echo "Failed to create n8n docker-compose.yml file"
  exit 1
fi

# Start the services
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting n8n..."
docker-compose up -d || { echo "Failed to start n8n"; exit 1; }

# Verify the service is running
echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for n8n to start..."
sleep 15

docker-compose ps | grep "Up" || { echo "n8n container is not running"; exit 1; }

echo "$(date '+%Y-%m-%d %H:%M:%S') - n8n setup completed successfully" 
#!/bin/bash
set -e  # Exit on error

# Log all output
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Flowise setup..."

# Create Docker volumes for Flowise
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating Docker volume for Flowise..."
docker volume create flowise_data || { echo "Failed to create flowise_data volume"; exit 1; }

# Configure Flowise
echo "$(date '+%Y-%m-%d %H:%M:%S') - Configuring Flowise..."
cd /opt/apps/flowise

# Create Flowise docker-compose.yml
echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating Flowise docker-compose file..."
cat > docker-compose.yml << EOL
version: '3.8'

services:
  flowise:
    image: flowiseai/flowise
    restart: always
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      - PORT=3000
      - FLOWISE_USERNAME=${FLOWISE_USERNAME}
      - FLOWISE_PASSWORD=${FLOWISE_PASSWORD}
      - DATABASE_PATH=/root/.flowise
      - APIKEY_PATH=/root/.flowise
      - SECRETKEY_PATH=/root/.flowise
      - LOG_PATH=/root/.flowise/logs
    volumes:
      - flowise_data:/root/.flowise

volumes:
  flowise_data:
    external: true
EOL

# Verify the docker-compose file was created
if [ ! -f docker-compose.yml ]; then
  echo "Failed to create Flowise docker-compose.yml file"
  exit 1
fi

# Start the services
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Flowise..."
docker-compose up -d || { echo "Failed to start Flowise"; exit 1; }

# Verify the service is running
echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for Flowise to start..."
sleep 15

docker-compose ps | grep "Up" || { echo "Flowise container is not running"; exit 1; }

echo "$(date '+%Y-%m-%d %H:%M:%S') - Flowise setup completed successfully" 
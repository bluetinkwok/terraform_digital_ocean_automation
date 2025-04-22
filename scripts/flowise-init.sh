#!/bin/bash

# Create Docker volumes for Flowise
docker volume create flowise_data

# Configure Flowise
cd /opt/apps/flowise

# Create Flowise docker-compose.yml
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

# Start the services
docker-compose up -d 
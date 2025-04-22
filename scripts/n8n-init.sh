#!/bin/bash

# Create Docker volumes for n8n
docker volume create n8n_data

# Configure n8n
cd /opt/apps/n8n

# Create n8n environment file
cat > .env << EOL
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=${N8N_USERNAME}
N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
N8N_HOST=${N8N_DOMAIN}
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=465
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-app-specific-password
N8N_SMTP_SENDER=your-email@gmail.com
EOL

# Create n8n docker-compose.yml
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

# Start the services
docker-compose up -d 
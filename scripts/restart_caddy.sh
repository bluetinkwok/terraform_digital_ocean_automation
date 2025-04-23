#!/bin/bash

# Set SSH key path if you have a specific key
# SSH_KEY="-i /path/to/your/key"

# Use the Digital Ocean server IP
SERVER_IP="178.128.213.205"

# The command to restart Caddy container
RESTART_CMD="cd /opt/apps/caddy && docker-compose down && docker-compose up -d"

echo "Attempting to restart Caddy on $SERVER_IP"
echo "You'll need to enter the SSH password when prompted"

ssh root@$SERVER_IP "$RESTART_CMD"

# Check status after restart
ssh root@$SERVER_IP "docker ps | grep caddy"

echo "Caddy restart attempt completed" 
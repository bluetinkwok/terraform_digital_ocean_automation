#!/bin/bash

# Set variables
BACKUP_DIR="/opt/backups"
N8N_DATA_DIR="/opt/apps/n8n/data"
FLOWISE_DATA_DIR="/opt/apps/flowise/data"
DATE=$(date +%Y-%m-%d-%H%M)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS}

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR
mkdir -p $BACKUP_DIR/n8n
mkdir -p $BACKUP_DIR/flowise

# Backup n8n data
echo "Starting n8n backup at $(date)..."
cd /opt/apps/n8n
docker-compose stop n8n
tar -czf $BACKUP_DIR/n8n/n8n-data-$DATE.tar.gz -C /opt/apps/n8n data
docker-compose start n8n

# Export n8n database from volume
echo "Exporting n8n database..."
docker run --rm -v n8n_data:/source -v $BACKUP_DIR/n8n:/backup ubuntu tar -czf /backup/n8n-volume-$DATE.tar.gz -C /source .
echo "n8n backup completed"

# Backup Flowise data
echo "Starting Flowise backup..."
cd /opt/apps/flowise
docker-compose stop flowise
tar -czf $BACKUP_DIR/flowise/flowise-data-$DATE.tar.gz -C /opt/apps/flowise data
docker-compose start flowise

# Export Flowise database from volume
echo "Exporting Flowise database..."
docker run --rm -v flowise_data:/source -v $BACKUP_DIR/flowise:/backup ubuntu tar -czf /backup/flowise-volume-$DATE.tar.gz -C /source .
echo "Flowise backup completed"

# Clean up old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed successfully at $(date)" 
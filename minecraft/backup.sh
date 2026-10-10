#!/bin/bash
# Save to: /opt/docker/minecraft/backup.sh

# Configuration
BACKUP_DIR="/mnt/media/minecraft/backups"
WORLD_DIR="/mnt/media/minecraft/data"
CONTAINER_NAME="mc-vanilla"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="minecraft-backup-${DATE}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

echo "Starting backup at $(date)"

# Tell server to save and disable auto-save temporarily
docker exec ${CONTAINER_NAME} rcon-cli save-off
docker exec ${CONTAINER_NAME} rcon-cli save-all flush

# Wait for save to complete
sleep 5

# Create backup
echo "Creating backup: ${BACKUP_FILE}"
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    -C /mnt/media/minecraft data/world \
    data/server.properties \
    data/whitelist.json \
    data/ops.json \
    data/banned-players.json \
    data/banned-ips.json

# Re-enable auto-save
docker exec ${CONTAINER_NAME} rcon-cli save-on

# Delete backups older than 7 days
find "${BACKUP_DIR}" -name "minecraft-backup-*.tar.gz" -mtime +7 -delete

echo "Backup completed: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "Backup size: $(du -h ${BACKUP_DIR}/${BACKUP_FILE} | cut -f1)"


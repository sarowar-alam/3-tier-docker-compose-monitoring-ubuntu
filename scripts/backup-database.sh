#!/bin/bash
# Database Backup Script for PostgreSQL in Docker
# Creates timestamped backup files and optionally uploads to S3

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER_NAME="bmi-postgres"
DB_NAME="${POSTGRES_DB:-bmidb}"
DB_USER="${POSTGRES_USER:-bmi_user}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/bmidb_backup_${TIMESTAMP}.sql"
RETENTION_DAYS=7

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Database Backup Script"
echo "=========================================="
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}ERROR: Container ${CONTAINER_NAME} is not running${NC}"
    exit 1
fi

# Create backup
echo "Creating backup of database: ${DB_NAME}"
echo "Backup file: ${BACKUP_FILE}"
echo ""

docker compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}SUCCESS: Backup created successfully!${NC}"
    echo "Size: ${BACKUP_SIZE}"
    echo "Location: ${BACKUP_FILE}"
else
    echo -e "${RED}ERROR: Backup failed${NC}"
    exit 1
fi

# Compress backup
echo ""
echo "Compressing backup..."
gzip "$BACKUP_FILE"
COMPRESSED_FILE="${BACKUP_FILE}.gz"
COMPRESSED_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
echo -e "${GREEN}SUCCESS: Backup compressed${NC}"
echo "Compressed size: ${COMPRESSED_SIZE}"
echo "File: ${COMPRESSED_FILE}"

# Optional: Upload to S3 (uncomment if you use AWS S3)
# if [ -n "$AWS_S3_BUCKET" ]; then
#     echo ""
#     echo "Uploading to S3..."
#     aws s3 cp "$COMPRESSED_FILE" "s3://${AWS_S3_BUCKET}/backups/"
#     if [ $? -eq 0 ]; then
#         echo -e "${GREEN}SUCCESS: Uploaded to S3${NC}"
#     else
#         echo -e "${YELLOW}WARNING: S3 upload failed${NC}"
#     fi
# fi

# Clean up old backups
echo ""
echo "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -name "bmidb_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
REMAINING=$(ls -1 "$BACKUP_DIR"/bmidb_backup_*.sql.gz 2>/dev/null | wc -l)
echo "Backups remaining: ${REMAINING}"

echo ""
echo "=========================================="
echo -e "${GREEN}Backup completed successfully!${NC}"
echo "=========================================="
echo ""
echo "To restore this backup, run:"
echo "  gunzip -c ${COMPRESSED_FILE} | docker compose exec -T postgres psql -U ${DB_USER} -d ${DB_NAME}"
echo ""

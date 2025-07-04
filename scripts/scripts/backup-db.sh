#!/bin/bash

# Config
DB_NAME="spatie"
DB_USER="root"
DB_PASS=""
DB_HOST="127.0.0.1"
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP_DIR="/c/Users/chandraprakash/Desktop/laravel-projects/updated-base-project-for-new-smarter-ways/backups"

# Ensure directory exists
mkdir -p "$BACKUP_DIR"

# Use full path to mysqldump
"C:/xampp/mysql/bin/mysqldump.exe" -u$DB_USER -p$DB_PASS -h $DB_HOST $DB_NAME > "$BACKUP_DIR/db_$DATE.sql"

# Tar files
tar -czf "$BACKUP_DIR/files_$DATE.tar.gz" storage app public .env composer.json

echo "✅ Backup completed: $BACKUP_DIR"

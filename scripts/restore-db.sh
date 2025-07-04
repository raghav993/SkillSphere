#!/bin/bash

DB_NAME="spatie"
DB_USER="root"
DB_PASS=""
DB_HOST="127.0.0.1"

DATE="2025-06-01_17-22"  # 👈 Change this to the correct date

BACKUP_DIR="/c/Users/chandraprakash/Desktop/laravel-projects/updated-base-project-for-new-smarter-ways/backups"

# Restore DB
echo "Restoring database..."
"C:/xampp/mysql/bin/mysql.exe" -u$DB_USER -p$DB_PASS -h $DB_HOST $DB_NAME < "$BACKUP_DIR/db_$DATE.sql"

# Extract files (app, storage, etc.)
echo "Restoring files..."
tar -xzf "$BACKUP_DIR/files_$DATE.tar.gz" -C .

echo "✅ Restore completed!"

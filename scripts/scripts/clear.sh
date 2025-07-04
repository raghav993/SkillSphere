#!/bin/bash

echo "🧹 Clearing Laravel cache and compiled files..."

php artisan config:clear
php artisan route:clear
php artisan cache:clear
php artisan view:clear
php artisan clear-compiled
php artisan event:clear
php artisan optimize:clear

echo "🔄 Re-caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "✅ All caches cleared and re-cached!"


#  run this by chmod +x scripts/clear.sh
# ./scripts/clear.sh

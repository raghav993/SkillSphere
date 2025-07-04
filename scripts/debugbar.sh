#!/bin/bash
# Laravel Debugbar installation and enable script

# Install barryvdh/laravel-debugbar via Composer
composer require barryvdh/laravel-debugbar --dev

# Publish the Debugbar config (optional, but recommended)
php artisan vendor:publish --provider="Barryvdh\\Debugbar\\ServiceProvider"

# Clear config cache to ensure Debugbar is enabled
php artisan config:clear

# Enable Debugbar in .env (if not already enabled)
if grep -q "DEBUGBAR_ENABLED" .env; then
    sed -i 's/DEBUGBAR_ENABLED=.*/DEBUGBAR_ENABLED=true/' .env
else
    echo "DEBUGBAR_ENABLED=true" >> .env
fi

echo "Laravel Debugbar installed and enabled!"

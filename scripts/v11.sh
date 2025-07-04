#!/bin/bash
set -e

# Step 1: Create new Laravel 11 project
composer create-project laravel/laravel example-app "11.*"
cd example-app

# Step 2: Install Laravel Breeze
composer require laravel/breeze --dev
php artisan breeze:install
npm install
npm run build

# Step 3: Install Laravel Debugbar
composer require barryvdh/laravel-debugbar --dev

# Step 4: Run migrations
php artisan migrate

# Step 5: Serve the application
php artisan serve

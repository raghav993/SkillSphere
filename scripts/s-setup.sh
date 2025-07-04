#!/bin/bash
set -e

# Step 1: api installation
php artisan install:api

# Step 2: Add HasApiTokens trait to User model
USER_MODEL="app/Models/User.php"

# Check if HasApiTokens is already used
if ! grep -q "HasApiTokens" "$USER_MODEL"; then
    # Add use statement after Authenticatable import
    sed -i "/use Illuminate\\\Foundation\\\Auth\\\User as Authenticatable;/a use Laravel\\\Sanctum\\\HasApiTokens;" "$USER_MODEL"
    # Add trait usage inside class block
    sed -i "/class User extends Authenticatable/a \\\n    use HasApiTokens;" "$USER_MODEL"
fi

# Step 3: Create AuthController with empty required methods
CONTROLLER_PATH="app/Http/Controllers/AuthController.php"
if [ ! -f "$CONTROLLER_PATH" ]; then
    cat > "$CONTROLLER_PATH" <<EOL
<?php

namespace App\\Http\\Controllers;

use Illuminate\\Http\\Request;

class AuthController extends Controller
{
    public function register(Request \$request)
    {
        // ...
    }

    public function login(Request \$request)
    {
        // ...
    }
    public function profile(Request \$request)
    {
        // ...
    }

    public function logout(Request \$request)
    {
        // ...
    }
}
EOL
fi

# Step 4: Add Sanctum routes to api.php
API_ROUTES="routes/api.php"
if ! grep -q "AuthController" "$API_ROUTES"; then
    cat >> "$API_ROUTES" <<EOL

use App\\Http\\Controllers\\AuthController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/profile', [AuthController::class, 'logout']);
    Route::post('/logout', [AuthController::class, 'logout']);
});
EOL
fi

# Step 5: Clear and cache configuration
php artisan config:clear
php artisan config:cache
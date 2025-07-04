#!/bin/bash
set -e
# Step 1: Install Passport
composer require laravel/passport
php artisan migrate
php artisan passport:install

# Step 2: Add HasApiTokens trait to User model
USER_MODEL="app/Models/User.php"
if ! grep -q "Laravel\\Passport\\HasApiTokens" "$USER_MODEL"; then
    sed -i "/use Illuminate\\Foundation\\Auth\\User as Authenticatable;/a \\
use Laravel\\Passport\\HasApiTokens;" "$USER_MODEL"
    sed -i "/class User extends Authenticatable/a \\
    use HasApiTokens;" "$USER_MODEL"
fi

# Step 3: Configure AuthServiceProvider
AUTH_PROVIDER="app/Providers/AuthServiceProvider.php"
if ! grep -q "Passport::routes()" "$AUTH_PROVIDER"; then
    sed -i "/use Illuminate\\Support\\Facades\\Gate;/a \\
use Laravel\\Passport\\Passport;" "$AUTH_PROVIDER"
    sed -i "/boot()/a \\
        Passport::routes();" "$AUTH_PROVIDER"
fi

# Step 4: Create AuthController
CONTROLLER_PATH="app/Http/Controllers/AuthController.php"
if [ ! -f "$CONTROLLER_PATH" ]; then
    cat > "$CONTROLLER_PATH" <<EOL
<?php

namespace App\\Http\\Controllers;

use Illuminate\\Http\\Request;
use App\\Models\\User;
use Illuminate\\Support\\Facades\\Hash;
use Illuminate\\Support\\Facades\\Auth;

class AuthController extends Controller
{
    public function register(Request \$request)
    {
        \$request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
        ]);

        \$user = User::create([
            'name' => \$request->name,
            'email' => \$request->email,
            'password' => Hash::make(\$request->password),
        ]);

        return response()->json(['user' => \$user], 201);
    }

    public function login(Request \$request)
    {
        \$request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt(\$request->only('email', 'password'))) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        \$user = Auth::user();
        \$token = \$user->createToken('auth_token')->accessToken;

        return response()->json(['token' => \$token, 'user' => \$user]);
    }

    public function logout(Request \$request)
    {
        \$request->user()->token()->revoke();
        return response()->json(['message' => 'Logged out successfully']);
    }
}
EOL
fi

# Step 5: Add Passport routes to api.php
API_ROUTES="routes/api.php"
if ! grep -q "AuthController" "$API_ROUTES"; then
    cat >> "$API_ROUTES" <<EOL

use App\\Http\\Controllers\\AuthController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:api')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
});
EOL
fi

# Step 6: Update config/auth.php to use passport
AUTH_CONFIG="config/auth.php"
sed -i "/'guards' => \[/a \\
        'api' => [\\
            'driver' => 'passport',\\
            'provider' => 'users',\\
        ]," "$AUTH_CONFIG"

# Step 7: Clear and cache configuration
php artisan config:clear
php artisan config:cache
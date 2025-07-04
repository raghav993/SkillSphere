#!/bin/bash

# Install Spatie Laravel Permission package
echo "🚀 Installing Spatie Laravel Permission package..."
composer require spatie/laravel-permission

# Publish Spatie config and migration
echo "🚀 Publishing Spatie config and migration..."
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"

# Run migrations
echo "🚀 Running migrations..."
php artisan migrate

# Add HasRoles trait to User model
USER_MODEL="app/Models/User.php"
echo "🚀 Adding HasRoles trait to User model..."
if ! grep -q "HasRoles" $USER_MODEL; then
  sed -i "/use Laravel\\\Sanctum\\\HasApiTokens;/a\ \ \ \ use Spatie\\\Permission\\\Traits\\\HasRoles;" $USER_MODEL
  echo "✅ HasRoles trait added to User model."
else
  echo "ℹ️ HasRoles trait already present in User model."
fi

# Create roles and permissions seeder
echo "🚀 Creating roles and permissions seeder..."
SEEDER="database/seeders/RolePermissionSeeder.php"
cat > $SEEDER <<EOL
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RolePermissionSeeder extends Seeder
{
    public function run()
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Create permissions
        \$permissions = [
            // Admin permissions
            'view_admin_dashboard',
            'manage_users',
            'manage_roles',
            'manage_permissions',

            // Content permissions
            'manage_posts',
            'publish_posts',

            // Author specific permissions
            'manage_own_posts',
        ];

        foreach (\$permissions as \$permission) {
            Permission::firstOrCreate(['name' => \$permission]);
        }

        // Create roles and assign permissions
        \$adminRole = Role::firstOrCreate(['name' => 'admin']);
        \$adminRole->givePermissionTo(Permission::all());

        \$editorRole = Role::firstOrCreate(['name' => 'editor']);
        \$editorRole->givePermissionTo([
            'view_admin_dashboard',
            'manage_posts',
            'publish_posts',
        ]);

        \$authorRole = Role::firstOrCreate(['name' => 'author']);
        \$authorRole->givePermissionTo([
            'view_admin_dashboard',
            'manage_own_posts',
        ]);

        \$userRole = Role::firstOrCreate(['name' => 'user']);
    }
}
EOL

# Create admin user seeder
echo "🚀 Creating admin user seeder..."
ADMIN_SEEDER="database/seeders/AdminUserSeeder.php"
cat > $ADMIN_SEEDER <<EOL
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run()
    {
        \$admin = User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Admin',
                'password' => Hash::make('password'),
            ]
        );

        \$admin->assignRole('admin');

        // Create example editor
        \$editor = User::firstOrCreate(
            ['email' => 'editor@example.com'],
            [
                'name' => 'Editor',
                'password' => Hash::make('password'),
            ]
        );

        \$editor->assignRole('editor');

        // Create example author
        \$author = User::firstOrCreate(
            ['email' => 'author@example.com'],
            [
                'name' => 'Author',
                'password' => Hash::make('password'),
            ]
        );

        \$author->assignRole('author');
    }
}
EOL

# Run seeders
echo "🚀 Running seeders..."
php artisan db:seed --class=RolePermissionSeeder
php artisan db:seed --class=AdminUserSeeder

# Create middleware for role and permission checks
echo "🚀 Creating middleware..."
MIDDLEWARE_DIR="app/Http/Middleware"
mkdir -p $MIDDLEWARE_DIR

# Role middleware
ROLE_MIDDLEWARE="$MIDDLEWARE_DIR/CheckRole.php"
cat > $ROLE_MIDDLEWARE <<EOL
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request \$request, Closure \$next, string \$role): Response
    {
        if (!\$request->user()->hasRole(\$role)) {
            abort(403, 'Unauthorized action.');
        }

        return \$next(\$request);
    }
}
EOL

# Permission middleware
PERMISSION_MIDDLEWARE="$MIDDLEWARE_DIR/CheckPermission.php"
cat > $PERMISSION_MIDDLEWARE <<EOL
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPermission
{
    public function handle(Request \$request, Closure \$next, string \$permission): Response
    {
        if (!\$request->user()->can(\$permission)) {
            abort(403, 'Unauthorized action.');
        }

        return \$next(\$request);
    }
}
EOL

# Register middleware in bootstrap/app.php for Laravel 11/12
echo "🚀 Registering middleware in bootstrap/app.php..."
BOOTSTRAP_APP="bootstrap/app.php"

if ! grep -q "CheckRole::class" $BOOTSTRAP_APP; then
  sed -i "/->withMiddleware(function (Middleware \$middleware) {/a\ \ \ \ \ \ \ \ \$middleware->alias(['role' => \App\Http\Middleware\CheckRole::class,]);" $BOOTSTRAP_APP
  sed -i "/->withMiddleware(function (Middleware \$middleware) {/a\ \ \ \ \ \ \ \ \$middleware->alias(['permission' => \App\Http\Middleware\CheckPermission::class,]);" $BOOTSTRAP_APP
  echo "✅ Middleware registered in bootstrap/app.php"
else
  echo "ℹ️ Middleware already registered in bootstrap/app.php"
fi

# Create admin and author controllers
echo "🚀 Creating controllers..."

# Admin Controller
ADMIN_CONTROLLER="app/Http/Controllers/AdminController.php"
cat > $ADMIN_CONTROLLER <<EOL
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class AdminController extends Controller
{
    public function __construct()
    {
        \$this->middleware(['auth', 'role:admin']);
    }

    public function dashboard()
    {
        return view('admin.dashboard');
    }

    public function users()
    {
        \$users = User::with('roles')->get();
        return view('admin.users.index', compact('users'));
    }

    public function roles()
    {
        \$roles = Role::with('permissions')->get();
        \$permissions = Permission::all();
        return view('admin.roles.index', compact('roles', 'permissions'));
    }
}
EOL

# Author Controller
AUTHOR_CONTROLLER="app/Http/Controllers/AuthorController.php"
cat > $AUTHOR_CONTROLLER <<EOL
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Post;

class AuthorController extends Controller
{
    public function __construct()
    {
        \$this->middleware(['auth', 'role:author|editor|admin']);
    }

    public function dashboard()
    {
        return view('author.dashboard');
    }

    public function posts()
    {
        \$posts = auth()->user()->posts;
        return view('author.posts.index', compact('posts'));
    }
}
EOL

# Create views directory structure
echo "🚀 Creating views with Bootstrap 5 layout..."
VIEWS_DIR="resources/views"
mkdir -p "$VIEWS_DIR/layouts"
mkdir -p "$VIEWS_DIR/admin"
mkdir -p "$VIEWS_DIR/admin/users"
mkdir -p "$VIEWS_DIR/admin/roles"
mkdir -p "$VIEWS_DIR/author"
mkdir -p "$VIEWS_DIR/author/posts"
mkdir -p "$VIEWS_DIR/components"
mkdir -p "$VIEWS_DIR/auth"

# Main layout
MAIN_LAYOUT="$VIEWS_DIR/layouts/app.blade.php"
cat > $MAIN_LAYOUT <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title') - {{ config('app.name') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
</head>
<body>
    <div class="d-flex flex-column min-vh-100">
        @include('layouts.navbar')

        <main class="flex-grow-1 py-4">
            <div class="container">
                @yield('content')
            </div>
        </main>

        @include('layouts.footer')
    </div>

    <!-- Bootstrap 5 JS Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    @stack('scripts')
</body>
</html>
EOL

# Navbar
NAVBAR="$VIEWS_DIR/layouts/navbar.blade.php"
cat > $NAVBAR <<EOL
<nav class="navbar navbar-expand-lg navbar-dark bg-primary">
    <div class="container">
        <a class="navbar-brand" href="/">{{ config('app.name') }}</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                @auth
                    @can('view_admin_dashboard')
                        <li class="nav-item">
                            <a class="nav-link" href="{{ route('admin.dashboard') }}">Admin Dashboard</a>
                        </li>
                    @endcan
                    @can('manage_own_posts')
                        <li class="nav-item">
                            <a class="nav-link" href="{{ route('author.posts') }}">My Posts</a>
                        </li>
                    @endcan
                @endauth
            </ul>
            <ul class="navbar-nav">
                @auth
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown">
                            {{ Auth::user()->name }}
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><a class="dropdown-item" href="#">Profile</a></li>
                            <li>
                                <form method="POST" action="{{ route('logout') }}">
                                    @csrf
                                    <button type="submit" class="dropdown-item">Logout</button>
                                </form>
                            </li>
                        </ul>
                    </li>
                @else
                    <li class="nav-item">
                        <a class="nav-link" href="{{ route('login') }}">Login</a>
                    </li>
                    @if (Route::has('register'))
                        <li class="nav-item">
                            <a class="nav-link" href="{{ route('register') }}">Register</a>
                        </li>
                    @endif
                @endauth
            </ul>
        </div>
    </div>
</nav>
EOL

# Footer
FOOTER="$VIEWS_DIR/layouts/footer.blade.php"
cat > $FOOTER <<EOL
<footer class="bg-dark text-white py-4 mt-auto">
    <div class="container text-center">
        <p class="mb-0">&copy; {{ date('Y') }} {{ config('app.name') }}. All rights reserved.</p>
    </div>
</footer>
EOL

# Admin Dashboard
ADMIN_DASHBOARD="$VIEWS_DIR/admin/dashboard.blade.php"
cat > $ADMIN_DASHBOARD <<EOL
@extends('layouts.app')

@section('title', 'Admin Dashboard')

@section('content')
<div class="card">
    <div class="card-header">
        <h5 class="card-title">Admin Dashboard</h5>
    </div>
    <div class="card-body">
        <div class="row">
            <div class="col-md-4 mb-4">
                <div class="card bg-primary text-white">
                    <div class="card-body">
                        <h5 class="card-title">Users</h5>
                        <p class="card-text display-4">{{ \App\Models\User::count() }}</p>
                        <a href="{{ route('admin.users') }}" class="text-white">View All</a>
                    </div>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card bg-success text-white">
                    <div class="card-body">
                        <h5 class="card-title">Roles</h5>
                        <p class="card-text display-4">{{ \Spatie\Permission\Models\Role::count() }}</p>
                        <a href="{{ route('admin.roles') }}" class="text-white">View All</a>
                    </div>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card bg-info text-white">
                    <div class="card-body">
                        <h5 class="card-title">Permissions</h5>
                        <p class="card-text display-4">{{ \Spatie\Permission\Models\Permission::count() }}</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
EOL

# Author Dashboard
AUTHOR_DASHBOARD="$VIEWS_DIR/author/dashboard.blade.php"
cat > $AUTHOR_DASHBOARD <<EOL
@extends('layouts.app')

@section('title', 'Author Dashboard')

@section('content')
<div class="card">
    <div class="card-header">
        <h5 class="card-title">Author Dashboard</h5>
    </div>
    <div class="card-body">
        <div class="row">
            <div class="col-md-6 mb-4">
                <div class="card bg-primary text-white">
                    <div class="card-body">
                        <h5 class="card-title">My Posts</h5>
                        <p class="card-text display-4">{{ auth()->user()->posts()->count() }}</p>
                        <a href="{{ route('author.posts') }}" class="text-white">View All</a>
                    </div>
                </div>
            </div>
            <div class="col-md-6 mb-4">
                <div class="card bg-success text-white">
                    <div class="card-body">
                        <h5 class="card-title">Create New Post</h5>
                        <p class="card-text">Start writing something amazing</p>
                        <a href="#" class="btn btn-light">Create Post</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
EOL

# Admin Users Index
ADMIN_USERS_INDEX="$VIEWS_DIR/admin/users/index.blade.php"
cat > $ADMIN_USERS_INDEX <<EOL
@extends('layouts.app')

@section('title', 'Manage Users')

@section('content')
<div class="card">
    <div class="card-header">
        <div class="d-flex justify-content-between align-items-center">
            <h5 class="card-title">User Management</h5>
            <a href="#" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> Add User
            </a>
        </div>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Roles</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach(\$users as \$user)
                    <tr>
                        <td>{{ \$user->id }}</td>
                        <td>{{ \$user->name }}</td>
                        <td>{{ \$user->email }}</td>
                        <td>
                            @foreach(\$user->roles as \$role)
                                <span class="badge bg-primary">{{ \$role->name }}</span>
                            @endforeach
                        </td>
                        <td>
                            <div class="btn-group" role="group">
                                <a href="#" class="btn btn-sm btn-outline-primary">
                                    <i class="bi bi-pencil"></i>
                                </a>
                                <a href="#" class="btn btn-sm btn-outline-danger">
                                    <i class="bi bi-trash"></i>
                                </a>
                            </div>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
EOL

# Admin Roles Index
ADMIN_ROLES_INDEX="$VIEWS_DIR/admin/roles/index.blade.php"
cat > $ADMIN_ROLES_INDEX <<EOL
@extends('layouts.app')

@section('title', 'Manage Roles')

@section('content')
<div class="card">
    <div class="card-header">
        <div class="d-flex justify-content-between align-items-center">
            <h5 class="card-title">Role Management</h5>
            <a href="#" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> Add Role
            </a>
        </div>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Permissions</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach(\$roles as \$role)
                    <tr>
                        <td>{{ \$role->id }}</td>
                        <td>{{ \$role->name }}</td>
                        <td>
                            @foreach(\$role->permissions as \$permission)
                                <span class="badge bg-info text-dark">{{ \$permission->name }}</span>
                            @endforeach
                        </td>
                        <td>
                            <div class="btn-group" role="group">
                                <a href="#" class="btn btn-sm btn-outline-primary">
                                    <i class="bi bi-pencil"></i>
                                </a>
                                <a href="#" class="btn btn-sm btn-outline-danger">
                                    <i class="bi bi-trash"></i>
                                </a>
                            </div>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
EOL

# Author Posts Index
AUTHOR_POSTS_INDEX="$VIEWS_DIR/author/posts/index.blade.php"
cat > $AUTHOR_POSTS_INDEX <<EOL
@extends('layouts.app')

@section('title', 'My Posts')

@section('content')
<div class="card">
    <div class="card-header">
        <div class="d-flex justify-content-between align-items-center">
            <h5 class="card-title">My Posts</h5>
            <a href="#" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> New Post
            </a>
        </div>
    </div>
    <div class="card-body">
        @if(session('success'))
            <div class="alert alert-success">
                {{ session('success') }}
            </div>
        @endif

        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Status</th>
                        <th>Created At</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse(\$posts as \$post)
                    <tr>
                        <td>{{ \$post->title }}</td>
                        <td>
                            <span class="badge bg-{{ \$post->published ? 'success' : 'warning' }}">
                                {{ \$post->published ? 'Published' : 'Draft' }}
                            </span>
                        </td>
                        <td>{{ \$post->created_at->format('M d, Y') }}</td>
                        <td>
                            <div class="btn-group" role="group">
                                <a href="#" class="btn btn-sm btn-outline-primary">
                                    <i class="bi bi-eye"></i>
                                </a>
                                <a href="#" class="btn btn-sm btn-outline-secondary">
                                    <i class="bi bi-pencil"></i>
                                </a>
                                <a href="#" class="btn btn-sm btn-outline-danger">
                                    <i class="bi bi-trash"></i>
                                </a>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" class="text-center">No posts found</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
EOL

# Add routes
echo "🚀 Adding routes..."
ROUTES_FILE="routes/web.php"
cat >> $ROUTES_FILE <<EOL

// Admin Routes
Route::prefix('admin')->middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/dashboard', [\App\Http\Controllers\AdminController::class, 'dashboard'])->name('admin.dashboard');
    Route::get('/users', [\App\Http\Controllers\AdminController::class, 'users'])->name('admin.users');
    Route::get('/roles', [\App\Http\Controllers\AdminController::class, 'roles'])->name('admin.roles');
});

// Author Routes
Route::prefix('author')->middleware(['auth', 'role:author|editor|admin'])->group(function () {
    Route::get('/dashboard', [\App\Http\Controllers\AuthorController::class, 'dashboard'])->name('author.dashboard');
    Route::get('/posts', [\App\Http\Controllers\AuthorController::class, 'posts'])->name('author.posts');
});
EOL

echo "✅ Setup completed with:"
echo "   - Laravel 11/12 middleware registration in bootstrap/app.php"
echo "   - Bootstrap 5 views and layouts"
echo "   - Complete admin and author panels"
echo "   - Responsive navigation"
echo "   - Role-based UI elements"
echo "   - Example dashboard widgets"
echo "   - Data tables for management"
echo "   - Proper route organization"

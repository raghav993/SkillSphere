#!/bin/bash

# Usage check
if [ -z "$1" ]; then
  echo "❌ Usage: ./generate-module.sh Post"
  exit 1
fi

# Get model name and lowercase plural name
MODEL_NAME=$1
MODEL_SNAKE=$(echo "$MODEL_NAME" | sed -E 's/([a-z])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')
MODEL_PLURAL="${MODEL_SNAKE}s"

echo "🚀 Generating module: $MODEL_NAME"

# 1. Model, Migration, Factory, Seeder, Policy, Controller
php artisan make:model $MODEL_NAME -mcr

# 2. Views folder & blade files
VIEW_PATH="resources/views/$MODEL_PLURAL"
mkdir -p $VIEW_PATH
touch $VIEW_PATH/index.blade.php
touch $VIEW_PATH/create.blade.php
touch $VIEW_PATH/edit.blade.php
touch $VIEW_PATH/show.blade.php
touch $VIEW_PATH/_form.blade.php

# 4. DTO
DTO_DIR="app/DTOs"
mkdir -p $DTO_DIR
DTO_PATH="${DTO_DIR}/${MODEL_NAME}DTO.php"
cat > $DTO_PATH <<EOL
<?php

namespace App\DTOs;

class ${MODEL_NAME}DTO
{
    // Define properties and a constructor for data transfer
}
EOL

# 5. Repository Interface
REPO_INTERFACE_DIR="app/Repositories/Contracts"
mkdir -p $REPO_INTERFACE_DIR
REPO_INTERFACE_PATH="${REPO_INTERFACE_DIR}/${MODEL_NAME}RepositoryInterface.php"
cat > $REPO_INTERFACE_PATH <<EOL
<?php

namespace App\Repositories\Contracts;

interface ${MODEL_NAME}RepositoryInterface
{
    // Define your contract methods here
}
EOL

# 6. Repository Implementation
REPO_IMPL_DIR="app/Repositories"
mkdir -p $REPO_IMPL_DIR
REPO_IMPL_PATH="${REPO_IMPL_DIR}/${MODEL_NAME}Repository.php"
cat > $REPO_IMPL_PATH <<EOL
<?php

namespace App\Repositories;

use App\Repositories\Contracts\\${MODEL_NAME}RepositoryInterface;
use App\Models\\${MODEL_NAME};

class ${MODEL_NAME}Repository implements ${MODEL_NAME}RepositoryInterface
{
    protected \$model;

    public function __construct(${MODEL_NAME} \$model)
    {
        \$this->model = \$model;
    }

    // Implement methods here
}
EOL

# 7. Service Class
SERVICE_DIR="app/Services"
mkdir -p $SERVICE_DIR
SERVICE_PATH="${SERVICE_DIR}/${MODEL_NAME}Service.php"
cat > $SERVICE_PATH <<EOL
<?php

namespace App\Services;

use App\Repositories\Contracts\\${MODEL_NAME}RepositoryInterface;
use App\DTOs\\${MODEL_NAME}DTO;

class ${MODEL_NAME}Service
{
    protected \$repo;

    public function __construct(${MODEL_NAME}RepositoryInterface \$repo)
    {
        \$this->repo = \$repo;
    }

    // Add service layer methods
}
EOL

# 8. Success message and guidance
echo "✅ All files/folders for '$MODEL_NAME' created successfully."

ROUTE_FILE="routes/web.php"
ROUTE_LINE="Route::resource('$MODEL_PLURAL', ${MODEL_NAME}Controller::class);"

# Check if the route already exists
if grep -Fxq "$ROUTE_LINE" "$ROUTE_FILE"; then
  echo "ℹ️ Route already exists in $ROUTE_FILE"
else
  echo "$ROUTE_LINE" >> "$ROUTE_FILE"
  echo "✅ Route added to $ROUTE_FILE"
fi

# 9. Path to AppServiceProvider
PROVIDER_FILE="app/Providers/AppServiceProvider.php"

# Binding line - simplified format
BIND_LINE="\\\$this->app->bind(${MODEL_NAME}RepositoryInterface::class, ${MODEL_NAME}Repository::class);"

# Check if already bound
if grep -Fq "$BIND_LINE" "$PROVIDER_FILE"; then
  echo "ℹ️ Interface binding already exists in AppServiceProvider"
else
  # Create a temporary file
  TEMP_FILE=$(mktemp)

  # Process the file
  awk -v bind_line="$BIND_LINE" '
    /public function register\(\)/ {
      print;
      in_register=1;
      next
    }
    in_register && /^\s*\{/ {
      print;
      print "        " bind_line;
      in_register=0;
      next
    }
    { print }
  ' "$PROVIDER_FILE" > "$TEMP_FILE"

  # Replace original file
  mv "$TEMP_FILE" "$PROVIDER_FILE"

  echo "✅ Interface binding added to AppServiceProvider"
fi

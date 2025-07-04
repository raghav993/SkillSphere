#!/bin/bash

# Usage check
if [ -z "$1" ]; then
  echo "❌ Usage: ./generate-module.sh Post"
  exit 1
fi

MODEL_NAME=$1
MODEL_SNAKE=$(echo "$MODEL_NAME" | sed -E 's/([a-z])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')
MODEL_PLURAL="${MODEL_SNAKE}s"

echo "🚀 Generating module: $MODEL_NAME"

# 1. Model
php artisan make:model $MODEL_NAME -mcr

# 2. API Controller for api 
# php artisan make:controller Http/Controllers/API/${MODEL_NAME}Controller --api

# 3. Form Request
php artisan make:request ${MODEL_NAME}/${MODEL_NAME}Request

# 4. Resource
php artisan make:resource ${MODEL_NAME}Resource

# 5. Repository
REPO_DIR="app/Repositories/${MODEL_NAME}"
mkdir -p $REPO_DIR

cat > ${REPO_DIR}/${MODEL_NAME}RepositoryInterface.php <<EOL
<?php

namespace App\Repositories\\$MODEL_NAME;

interface ${MODEL_NAME}RepositoryInterface
{
    // Define contract methods
}
EOL

cat > ${REPO_DIR}/${MODEL_NAME}Repository.php <<EOL
<?php

namespace App\Repositories\\$MODEL_NAME;

use App\Models\\$MODEL_NAME;

class ${MODEL_NAME}Repository implements ${MODEL_NAME}RepositoryInterface
{
    protected \$model;

    public function __construct($MODEL_NAME \$model)
    {
        \$this->model = \$model;
    }

    // Implement methods
}
EOL

# 6. Service
SERVICE_FILE="app/Services/${MODEL_NAME}Service.php"
mkdir -p app/Services
cat > $SERVICE_FILE <<EOL
<?php

namespace App\Services;

use App\Repositories\\$MODEL_NAME\\${MODEL_NAME}RepositoryInterface;

class ${MODEL_NAME}Service
{
    protected \$repo;

    public function __construct(${MODEL_NAME}RepositoryInterface \$repo)
    {
        \$this->repo = \$repo;
    }

    // Business logic here
}
EOL

# 7. Views (optional)
VIEW_PATH="resources/views/$MODEL_PLURAL"
mkdir -p $VIEW_PATH
touch $VIEW_PATH/index.blade.php
touch $VIEW_PATH/create.blade.php
touch $VIEW_PATH/edit.blade.php
touch $VIEW_PATH/show.blade.php
touch $VIEW_PATH/_form.blade.php

# 8. Route (web)
ROUTE_FILE="routes/web.php"
ROUTE_LINE="Route::resource('$MODEL_PLURAL', \\App\\Http\\Controllers\\API\\${MODEL_NAME}Controller::class);"

if grep -Fxq "$ROUTE_LINE" "$ROUTE_FILE"; then
  echo "ℹ️ Route already exists in $ROUTE_FILE"
else
  echo "$ROUTE_LINE" >> "$ROUTE_FILE"
  echo "✅ Route added to $ROUTE_FILE"
fi

# 9. Binding in AppServiceProvider
PROVIDER_FILE="app/Providers/AppServiceProvider.php"
BIND_LINE="\\\$this->app->bind(App\Repositories\\$MODEL_NAME\\${MODEL_NAME}RepositoryInterface::class, App\Repositories\\$MODEL_NAME\\${MODEL_NAME}Repository::class);"

if grep -Fq "$BIND_LINE" "$PROVIDER_FILE"; then
  echo "ℹ️ Binding already exists in AppServiceProvider"
else
  TEMP_FILE=$(mktemp)

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

  mv "$TEMP_FILE" "$PROVIDER_FILE"
  echo "✅ Binding added to AppServiceProvider"
fi

echo "✅ Module structure for $MODEL_NAME created successfully."

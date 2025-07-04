# Check if at least one model name is provided
if [ $# -eq 0 ]; then
  echo "⚠️  Usage: ./make-models.sh Model1 Model2 Model3 ..."
  exit 1
fi

# Loop through all arguments
for model in "$@"
do
  echo "🚀 Creating model: $model"
  php artisan make:model "$model" -a
done


#  command to run this file for making dynamic models in onle click
#  command:  ./make-models.sh Post Comment Category Tag

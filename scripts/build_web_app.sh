# Default env file
ENV_FILE=".env.prod"

# Set the Flutter command based on environment
FLUTTER_CMD="flutter"
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "Running locally"
    FLUTTER_CMD="fvm flutter"
fi

./scripts/pre_build.sh $ENV_FILE

if [ "$ENV_FILE" != ".env.prod" ]; then
    $FLUTTER_CMD build web \
        --dart-define-from-file=$ENV_FILE \
        --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S") \
        --release    
else
    $FLUTTER_CMD build web \
        --dart-define-from-file=$ENV_FILE \
        --release    
fi

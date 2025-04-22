# Set environment, default to prod if not specified
ENV=${1:-prod}

# Set the Flutter command based on environment
FLUTTER_CMD="flutter"
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "Running locally"
    FLUTTER_CMD="fvm flutter"
fi

if [ "$ENV" = "staging" ]; then
    echo "Building for staging"
    $FLUTTER_CMD build web \
        --dart-define-from-file=.env.prod \
        --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S") \
        --release    
else
    echo "Building for prod"
    $FLUTTER_CMD build web \
        --dart-define-from-file=.env.prod \
        --release    
fi

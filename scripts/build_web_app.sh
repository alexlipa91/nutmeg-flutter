# Set environment, default to prod if not specified
ENV=${1:-prod}

if [ "$ENV" = "staging" ]; then
    echo "Building for staging"
    fvm flutter build web \
        -t lib/screens/Launch.dart \
        --dart-define-from-file=.env.prod \
        --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S") \
        --release    
else
    echo "Building for prod"
    fvm flutter build web \
        -t lib/screens/Launch.dart \
        --dart-define-from-file=.env.prod \
        --release    
fi

# Read environment variables if set, otherwise use defaults
ENV_FILE=${ENV_FILE:-".env.prod"}
MODE=${MODE:-"prod"}

echo "Running build with env file: $ENV_FILE and mode: $MODE"

# Set the Flutter command based on environment
FLUTTER_CMD="flutter"
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "Running locally"
    FLUTTER_CMD="fvm flutter"
fi

./scripts/pre_build.sh $ENV_FILE

COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
COMMIT_TIMESTAMP=$(git log -1 --format=%ci HEAD 2>/dev/null || echo "")

if [ "$MODE" == "prod" ]; then
    $FLUTTER_CMD build web \
        --dart-define-from-file=$ENV_FILE \
        --dart-define=COMMIT_SHA=$COMMIT_SHA \
        --dart-define=COMMIT_TIMESTAMP="$COMMIT_TIMESTAMP" \
        --pwa-strategy=none \
        --release
else
    $FLUTTER_CMD build web \
        --debug \
        --dart-define-from-file=$ENV_FILE \
        --dart-define=COMMIT_SHA=$COMMIT_SHA \
        --dart-define=COMMIT_TIMESTAMP="$COMMIT_TIMESTAMP" \
        --pwa-strategy=none \
        --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S")        
fi

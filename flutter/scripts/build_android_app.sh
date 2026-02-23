# Read environment variables if set, otherwise use defaults
ENV_FILE=${ENV_FILE:-".env.prod"}

echo "Running build with env file: $ENV_FILE"

./scripts/pre_build.sh $ENV_FILE

COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
COMMIT_TIMESTAMP=$(git log -1 --format=%ci HEAD 2>/dev/null || echo "")

flutter build appbundle --release \
    --dart-define-from-file=$ENV_FILE \
    --dart-define=COMMIT_SHA=$COMMIT_SHA \
    --dart-define=COMMIT_TIMESTAMP="$COMMIT_TIMESTAMP"

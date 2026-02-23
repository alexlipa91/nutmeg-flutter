#!/bin/bash

# Default env file
ENV_FILE=".env.local"

./scripts/pre_build.sh $ENV_FILE

COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
COMMIT_TIMESTAMP=$(git log -1 --format=%ci HEAD 2>/dev/null || echo "")

# The following envs can be overridden with --dart-define
# Full list in app_config.dart
#
# TEST_MODE=true
# BACKEND_URL=http://localhost:8080
# TEST_MODE_ORGANIZER=true
# INJECT_AUTH_TOKEN_UID=...
# GOOGLE_API_KEY=...
# FIREBASE_VAPID_KEY=...

fvm flutter run \
    -d web-server --web-hostname=0.0.0.0 --web-port=7357 \
    --dart-define-from-file="$ENV_FILE" \
    --dart-define=COMMIT_SHA=$COMMIT_SHA \
    --dart-define=COMMIT_TIMESTAMP="$COMMIT_TIMESTAMP" \
    --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

#!/bin/bash

# Default env file
ENV_FILE=".env.prod"

# Set default device if not specified
if [ -z "$DEVICE" ]; then
    DEVICE="web-server"
fi

./scripts/pre_build.sh $ENV_FILE

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
    --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S") \
    --dart-define=BACKEND_URL=http://localhost:8080 \
    --dart-define=TEST_MODE=true

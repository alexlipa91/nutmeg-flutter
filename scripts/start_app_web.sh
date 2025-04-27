#!/bin/bash

# Default env file
ENV_FILE=".env.prod"

# If an argument is provided, use it as the env file
if [ $# -eq 1 ]; then
    ENV_FILE="$1"
fi

# Check if the env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found!"
    exit 1
fi

./scripts/pre_build.sh $ENV_FILE

fvm flutter run \
    -d web-server \
    --web-hostname=0.0.0.0 \
    --web-port=7357 \
    --dart-define-from-file="$ENV_FILE" \
    --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

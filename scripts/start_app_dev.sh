#!/bin/bash

# Default env file
ENV_FILE=".env.local"

# If an argument is provided, use it as the env file
if [ $# -eq 1 ]; then
    ENV_FILE="$1"
fi

# Check if the env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found!"
    exit 1
fi

flutter run \
    -t lib/screens/Launch.dart \
    -d chrome \
    --web-port=7357 \
    --dart-define-from-file="$ENV_FILE"
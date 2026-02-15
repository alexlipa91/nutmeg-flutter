#!/bin/bash

# Default env file
ENV_FILE=".env.prod"

# Set default device if not specified
if [ -z "$DEVICE" ]; then
    DEVICE="web-server"
fi

# Set default server mode if not specified (local or remote)
if [ -z "$SERVER_MODE" ]; then
    SERVER_MODE="remote"
fi

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

PARAMETRICS_ARGS=""
if [ "$DEVICE" == "web-server" ]; then
    PARAMETRICS_ARGS="-d web-server --web-hostname=0.0.0.0"
elif [ "$DEVICE" == "chrome" ]; then
    PARAMETRICS_ARGS="-d chrome"
elif [ "$DEVICE" == "android" ]; then
    PARAMETRICS_ARGS="-d emulator-5554"
fi

# Set backend URL based on server mode
BACKEND_URL_ARG=""
if [ "$SERVER_MODE" == "local" ]; then
    BACKEND_URL_ARG="--dart-define=BACKEND_URL=http://localhost:8080"
    echo "Using local backend: http://localhost:8080"
else
    echo "Using remote backend (from env file or default)"
fi

fvm flutter run \
    $PARAMETRICS_ARGS \
    --web-port=7357 \
    --dart-define-from-file="$ENV_FILE" \
    --dart-define=BUILD_TIMESTAMP=$(date "+%Y%m%d-%H%M%S") \
    --dart-define=TEST_MODE=true \
    $BACKEND_URL_ARG

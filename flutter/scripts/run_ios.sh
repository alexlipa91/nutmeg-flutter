#!/bin/bash

# Default values
DEVICE="00008140-00113D5A2247001C"
ENV_FILE=".env.prod"
PHYSICAL_DEVICE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -p|--physical)
            PHYSICAL_DEVICE=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./scripts/run_ios.sh [options]"
            echo ""
            echo "Options:"
            echo "  -d, --device   Device name/id (simulator by default)"
            echo "  -e, --env      Environment file (default: .env.prod)"
            echo "  -p, --physical Run on connected physical iOS device"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Connected/available Flutter devices:"
            flutter devices
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "$PHYSICAL_DEVICE" == false ]]; then
    echo "Booting simulator $DEVICE..."
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    open -a Simulator
else
    echo "Using physical iOS device target: $DEVICE"
fi

./scripts/pre_build.sh "$ENV_FILE"

echo "Running app on $DEVICE with $ENV_FILE..."
flutter run -d "$DEVICE" \
    --dart-define-from-file="$ENV_FILE"

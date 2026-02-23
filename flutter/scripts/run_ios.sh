#!/bin/bash

# Default values
DEVICE="iPhone 16 Pro Max"
ENV_FILE=".env.prod"

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
        -h|--help)
            echo "Usage: ./scripts/run_ios.sh [options]"
            echo ""
            echo "Options:"
            echo "  -d, --device   Simulator device name (default: iPhone 16 Pro Max)"
            echo "  -e, --env      Environment file (default: .env.prod)"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Available devices:"
            xcrun simctl list devices available | grep -i "iphone\|ipad"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Booting $DEVICE..."
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator

./scripts/pre_build.sh "$ENV_FILE"

COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
COMMIT_TIMESTAMP=$(git log -1 --format=%ci HEAD 2>/dev/null || echo "")

echo "Running app on $DEVICE with $ENV_FILE..."
flutter run -d "$DEVICE" \
    --dart-define-from-file="$ENV_FILE" \
    --dart-define=COMMIT_SHA=$COMMIT_SHA \
    --dart-define=COMMIT_TIMESTAMP="$COMMIT_TIMESTAMP"

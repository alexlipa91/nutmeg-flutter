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

echo "Running app on $DEVICE with $ENV_FILE..."
flutter run -d "$DEVICE" --dart-define-from-file="$ENV_FILE"

#!/bin/bash
set -e

# Set track, default to internal if not specified
TRACK=${1:-internal}

if [ "$TRACK" = "internal" ]; then
    LANE_NAME="playstoreInternalTest"
elif [ "$TRACK" = "production" ]; then
    LANE_NAME="playstoreProduction"
else
    echo "Invalid track: $TRACK. Use 'internal' or 'production'."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build the app bundle
echo "Building app bundle..."
(cd "$FLUTTER_DIR" && ./scripts/build_android_app.sh)

# Deploy with fastlane
echo "Deploying with lane $LANE_NAME"
(cd "$FLUTTER_DIR/android" && fastlane $LANE_NAME)

echo "Done! Deployed to $TRACK track."

#!/bin/bash
set -e

TRACK=${1:-internal}

if [ "$TRACK" = "internal" ]; then
    LANE_NAME="playstoreInternalTest"
elif [ "$TRACK" = "production" ]; then
    LANE_NAME="playstoreProduction"
else
    echo "Invalid track: $TRACK. Use 'internal' or 'production'."
    exit 1
fi

echo "Building and deploying to $TRACK track..."
(cd android && bundle exec fastlane $LANE_NAME)

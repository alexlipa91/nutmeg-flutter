# Set track, default to internal if not specified
TRACK=$1

if [ "$TRACK" = "internal" ]; then
    LANE_NAME="playstoreInternalTest"
elif [ "$TRACK" = "production" ]; then
    LANE_NAME="playstoreProduction"
else
    echo "Invalid track: $TRACK"
    exit 1
fi

flutter build appbundle --release
echo "Deploying with lane $LANE_NAME"
(cd android && fastlane $LANE_NAME)

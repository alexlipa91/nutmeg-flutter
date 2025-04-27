# Set environment, default to prod if not specified
CHANNEL=${CHANNEL:-"live"}

echo "Deploying to $CHANNEL"
firebase deploy --only hosting:$CHANNEL
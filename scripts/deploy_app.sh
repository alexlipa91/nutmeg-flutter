# Set environment, default to prod if not specified
ENV=${1:-prod}

./scripts/build_web_app.sh $ENV

if [ "$ENV" = "staging" ]; then
    echo "Deploying to staging"
    firebase deploy --only hosting:staging
else
    firebase deploy --only hosting
fi

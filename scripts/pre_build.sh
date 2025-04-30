# Default env file
ENV_FILE=".env.local"

# If an argument is provided, use it as the env file
if [ $# -eq 1 ]; then
    ENV_FILE="$1"
fi

echo "Running pre-build script with env file: $ENV_FILE"

source $ENV_FILE

# Replace the VAPID key in the firebase-messaging-sw.js file
sed "s|__ENV__FIREBASE_API_KEY__|${FIREBASE_VAPID_KEY}|g" web/firebase-messaging-sw.js.template > web/firebase-messaging-sw.js

# Generate the translations
./scripts/generate_translations.sh

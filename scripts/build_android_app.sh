# Read environment variables if set, otherwise use defaults
ENV_FILE=${ENV_FILE:-".env.prod"}

echo "Running build with env file: $ENV_FILE"

flutter build appbundle --release --dart-define-from-file=$ENV_FILE

flutter build web --release --no-sound-null-safety -t lib/screens/Launch.dart --dart-define="LOCALE=$1"
firebase hosting:channel:deploy $1
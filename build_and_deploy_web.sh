flutter build web --release --web-renderer=canvaskit --no-sound-null-safety -t lib/screens/Launch.dart
firebase deploy

flutter build web --release --web-renderer=canvaskit --no-sound-null-safety -t lib/screens/Launch.dart --dart-define="LOCALE=pt"
firebase hosting:channel:deploy pt
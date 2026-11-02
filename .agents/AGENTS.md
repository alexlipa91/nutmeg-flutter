# Agent instructions

## Flutter app (`flutter/`)

- Flutter is managed with FVM: use `fvm flutter ...`, not `flutter ...` (it is not on PATH).
- Analyze a file: `cd flutter && fvm flutter analyze lib/screens/UserPage.dart`.

## Running locally (web)

- Use `cd flutter && ./scripts/run_web.sh`. It serves on port 7357 (`-d web-server`), reads `flutter/.env.local`, and runs `pre_build.sh` first. Open http://localhost:7357 in Chrome.
- Don't use plain `fvm flutter run -d chrome`: it skips `.env.local`, and the process exits when the debug connection to Chrome drops.
- Run it as a background command; it keeps running until stopped.
- Android/iOS: `scripts/run_android.sh`, `scripts/run_ios.sh`. Setup details are in `flutter/README.md`.

## Assets

- Images live in `flutter/assets/`. The `assets/` directory is already declared in `pubspec.yaml`, so a new file there needs no pubspec change.

## Profile screen

- `flutter/lib/screens/UserPage.dart` holds the profile UI. Profile stats come from `UserDetails` (`getNumJoinedMatches()`, `getScoreMatches()`, `getNumManOfTheMatch()`, `numWin`, `numDraw`, `numLoss`).
- `UserAvatar(radius, userDetails)` (in `widgets/Avatar.dart`) renders the user's picture.

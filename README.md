# Nutmeg

A new Flutter project.

## Releasing iOS

Run

`cd ios && fastalane release`

Since the IPA build is not managed by flutter in fastlane the version doesn't get updated properly. For now the way to bump version is to

- change it in `pubspec.yaml`
- change it in `ios/fastlane/Deliverfile`
- change it in `ios/Flutter/Generated.xconfig`

# Nutmeg

## Rollout

Versioning is managed in `pubspec.yaml`

Run `python bump_and_tag.py` to
- increase the patch version and the build number (e.g. `1.0.10+10` will become `1.0.11+11`)
- tag the code

Afterwards push tags `git push --follow-tags`

Github Workflows will deploy in internal tests for Playstore and TestFlight for Appstore.

Once you are satisfied with test versions, manually log in in the Playstore or Appstore developer portal and 
promote the build to production

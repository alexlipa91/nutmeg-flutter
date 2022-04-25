# Nutmeg

## Rollout

Versioning is managed in `pubspec.yaml`

Run `python bump_and_tag.py` to
- increase the patch version and the build number (e.g. `1.0.10+10` will become `1.0.11+11`)
- tag the code
- push (both tags and commits)

Github Workflows will deploy in internal tests for Playstore and TestFlight for Appstore.

Once you are satisfied with test versions, run 

```bash
./create_release_from_tag.sh <tag_name> <changes> 
```

e.g.

```bash
./create_release_from_tag.sh v1.1.24+167 "UI fixes/nFix bug in Match page" 
```

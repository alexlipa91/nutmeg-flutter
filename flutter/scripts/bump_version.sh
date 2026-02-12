#!/bin/bash

# Bumps the version string (X.Y.Z) in pubspec.yaml, commits, and pushes.
# Usage:
#   ./scripts/bump_version.sh          # patch: 1.2.3 -> 1.2.4
#   ./scripts/bump_version.sh minor    # minor: 1.2.3 -> 1.3.0
#   ./scripts/bump_version.sh major    # major: 1.2.3 -> 2.0.0

BUMP_TYPE=${1:-patch}

get_current_version() {
    grep -E '^version: ' pubspec.yaml | head -n 1 | sed -E 's/version: ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+).*/\1 \2 \3 \4/'
}

read MAJOR MINOR PATCH BUILD <<< $(get_current_version)

case $BUMP_TYPE in
    patch)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$MINOR
        NEW_PATCH=$((PATCH + 1))
        ;;
    minor)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$((MINOR + 1))
        NEW_PATCH=0
        ;;
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_MINOR=0
        NEW_PATCH=0
        ;;
    *)
        echo "Usage: $0 [patch|minor|major]"
        exit 1
        ;;
esac

NEW_VERSION="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
NEW_BUILD=$((BUILD + 1))

echo "Bumping version: $MAJOR.$MINOR.$PATCH+$BUILD -> $NEW_VERSION+$NEW_BUILD ($BUMP_TYPE)"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version: .*/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
else
    sed -i "s/^version: .*/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
fi

# Commit and push
git add pubspec.yaml
git commit -m "[promote] Release $NEW_VERSION+$NEW_BUILD"

echo "Done! Version bumped to $NEW_VERSION+$NEW_BUILD"
echo "Pushing..."
git push

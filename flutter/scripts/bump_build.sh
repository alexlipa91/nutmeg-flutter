#!/bin/bash

# Bumps the build number (+N) in pubspec.yaml, commits with [deploy] marker, and pushes.
# The [deploy] in the commit message triggers the CI/CD workflows.

get_current_version() {
    grep -E '^version: ' pubspec.yaml | head -n 1 | sed -E 's/version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\1 \2/'
}

read VERSION BUILD <<< $(get_current_version)
NEW_BUILD=$((BUILD + 1))

echo "Bumping build number: $VERSION+$BUILD -> $VERSION+$NEW_BUILD"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml
else
    sed -i "s/^version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml
fi

# Commit with [deploy] marker to trigger CI
git add pubspec.yaml
git commit -m "[deploy] Bump build to $VERSION+$NEW_BUILD"

echo "Done! Build bumped to $VERSION+$NEW_BUILD"
echo "Pushing..."
git push

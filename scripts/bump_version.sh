#!/bin/bash

# Function to get current version from pubspec.yaml
get_current_version() {
    grep -E '^version: ' pubspec.yaml | head -n 1 | sed -E 's/version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\1 \2/'
}

# Function to bump patch version
bump_patch() {
    local version=$1
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    local patch=$(echo $version | cut -d. -f3)
    echo "$major.$minor.$((patch + 1))"
}

# If version is not provided, bump patch version
if [ -z "$1" ]; then
    read CURRENT_VERSION CURRENT_BUILD <<< $(get_current_version)
    VERSION=$(bump_patch $CURRENT_VERSION)
    BUILD_NUMBER=$((CURRENT_BUILD + 1))
    echo "No version specified. Bumping patch version from $CURRENT_VERSION+$CURRENT_BUILD to $VERSION+$BUILD_NUMBER"
else
    VERSION=$1
    # Validate version format (X.Y.Z)
    if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be in format X.Y.Z"
        exit 1
    fi
    read CURRENT_VERSION CURRENT_BUILD <<< $(get_current_version)
    BUILD_NUMBER=$((CURRENT_BUILD + 1))
fi

# Update pubspec.yaml
echo "Updating version to $VERSION+$BUILD_NUMBER in pubspec.yaml..."
# Use a more robust sed command that works across different Unix-like systems
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
else
    # Linux and other Unix-like systems
    sed -i "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
fi

# Create commit
echo "Creating commit..."
git add pubspec.yaml
git commit -m "Bump version to $VERSION+$BUILD_NUMBER"


exit 0

# Create tag
echo "Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create tag"
    exit 1
fi

echo "Done! Version bumped to $VERSION+$BUILD_NUMBER"
echo "Pushing the commit and tag"
git push && git push --tags 
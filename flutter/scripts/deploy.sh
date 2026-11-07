#!/bin/bash
set -e

# Deploy script for Nutmeg
#
# Usage:
#   ./scripts/deploy.sh test                    # bump build, deploy to TestFlight + Play Store internal
#   ./scripts/deploy.sh prod                    # bump build + patch version, tag, deploy to production
#   ./scripts/deploy.sh prod 1.2.3              # bump build + set version, tag, deploy to production
#   ./scripts/deploy.sh prod patch              # bump build + patch version (1.2.3 -> 1.2.4), tag, deploy to production
#   ./scripts/deploy.sh prod minor              # bump build + minor version (1.2.3 -> 1.3.0), tag, deploy to production

ENV=$1

if [[ -z "$ENV" ]]; then
    echo "Usage: $0 <test|prod> [version|patch|minor|major]"
    exit 1
fi

# Parse current version from pubspec.yaml
get_current_version() {
    grep -E '^version: ' pubspec.yaml | head -n 1 | sed -E 's/version: ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+).*/\1 \2 \3 \4/'
}

# App Store rejects a reused marketing version. Play Store only needs a new build.
version_is_greater() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        split(a, av, "."); split(b, bv, ".");
        for (i = 1; i <= 3; i++) {
            ai = av[i] + 0; bi = bv[i] + 0;
            if (ai > bi) exit 0;
            if (ai < bi) exit 1;
        }
        exit 1;
    }'
}

read MAJOR MINOR PATCH BUILD <<< $(get_current_version)
NEW_BUILD=$((BUILD + 1))
CURRENT_VERSION="$MAJOR.$MINOR.$PATCH"

if [[ "$ENV" == "test" ]]; then
    NEW_VERSION="$CURRENT_VERSION"
    echo "=== TEST DEPLOY ==="
    echo "Bumping build: $CURRENT_VERSION+$BUILD -> $NEW_VERSION+$NEW_BUILD"

elif [[ "$ENV" == "prod" ]]; then
    # No argument bumps the patch. A build-only bump is rejected by the App Store
    # once that marketing version already exists.
    VERSION_ARG=${2:-patch}

    # Determine new version
    case $VERSION_ARG in
        patch)
            NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
            ;;
        minor)
            NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
            ;;
        major)
            NEW_VERSION="$((MAJOR + 1)).0.0"
            ;;
        *)
            # Treat as explicit version string (validate format)
            if [[ ! "$VERSION_ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Error: invalid version format '$VERSION_ARG'. Expected X.Y.Z, patch, minor, or major"
                exit 1
            fi
            NEW_VERSION="$VERSION_ARG"
            ;;
    esac

    if ! version_is_greater "$NEW_VERSION" "$CURRENT_VERSION"; then
        echo "Error: prod version must be higher than $CURRENT_VERSION (App Store rejects a reused version)."
        echo "  e.g. $0 prod          # $CURRENT_VERSION -> patch"
        echo "  e.g. $0 prod minor"
        exit 1
    fi

    echo "=== PROD DEPLOY ==="
    echo "Bumping version: $CURRENT_VERSION+$BUILD -> $NEW_VERSION+$NEW_BUILD"
else
    echo "Error: first argument must be 'test' or 'prod'"
    exit 1
fi

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version: .*/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
else
    sed -i "s/^version: .*/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
fi

# Commit
git add pubspec.yaml
COMMIT_MSG="[deploy_${ENV}] $NEW_VERSION+$NEW_BUILD"
git commit -m "$COMMIT_MSG"

# Tag for prod
if [[ "$ENV" == "prod" ]]; then
    TAG="v$NEW_VERSION+$NEW_BUILD"
    echo "Creating tag: $TAG"
    git tag "$TAG"
fi

echo ""
echo "Done! $NEW_VERSION+$NEW_BUILD"
echo "Pushing..."
if [[ "$ENV" == "prod" ]]; then
    git push && git push --tags
else
    git push
fi

#!/bin/bash

# Exit on error
set -e

# Check if version is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <new-version>"
    echo "Example: $0 1.0.4"
    exit 1
fi

NEW_VERSION=$1
LOCAL_FORMULA_PATH="dopctl.rb"  # Formula in the current directory
TAP_FORMULA_PATH="Formula/dopctl.rb"  # Formula in the tap repository
REPO="sysintelligent/devops-bridge"
TAP_REPO="sysintelligent/homebrew-sysintelligent"
TAP_DIR="${HOME}/homebrew-sysintelligent"

# Check if tag exists and delete it if it does
if git tag -l "v${NEW_VERSION}" > /dev/null; then
    echo "Tag v${NEW_VERSION} already exists locally. Deleting..."
    git tag -d "v${NEW_VERSION}" || true
fi
if git ls-remote --tags origin "refs/tags/v${NEW_VERSION}" | grep -q "refs/tags/v${NEW_VERSION}"; then
    echo "Tag v${NEW_VERSION} exists remotely. Deleting..."
    git push origin ":refs/tags/v${NEW_VERSION}" || true
fi

# Create and push new tag
echo "Creating new tag v${NEW_VERSION}..."
git tag "v${NEW_VERSION}"
git push origin "v${NEW_VERSION}"

# Wait for GitHub to create the release and tarball
echo "Waiting for GitHub to create the release..."
sleep 30  # Increased wait time

# Get the SHA256 hash of the new release with retries
echo "Getting SHA256 hash..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -L "https://github.com/${REPO}/archive/v${NEW_VERSION}.tar.gz" -o "devops-bridge-${NEW_VERSION}.tar.gz"; then
        NEW_SHA256=$(shasum -a 256 "devops-bridge-${NEW_VERSION}.tar.gz" | cut -d' ' -f1)
        if [ ! -z "$NEW_SHA256" ]; then
            break
        fi
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "Retry $RETRY_COUNT of $MAX_RETRIES..."
        sleep 10
    fi
done

if [ -z "$NEW_SHA256" ]; then
    echo "Failed to get SHA256 hash after $MAX_RETRIES attempts"
    exit 1
fi

cd - > /dev/null
rm -rf "$TEMP_DIR"

# Update local formula in devops-bridge repository
echo "Updating local formula..."
sed -i '' "s|url \".*\"|url \"https://github.com/${REPO}/archive/v${NEW_VERSION}.tar.gz\"|" "$LOCAL_FORMULA_PATH"
sed -i '' "s|sha256 \".*\"|sha256 \"${NEW_SHA256}\"|" "$LOCAL_FORMULA_PATH"

# Verify local changes
echo "Verifying local changes..."
if ! grep -q "sha256 \"${NEW_SHA256}\"" "$LOCAL_FORMULA_PATH"; then
    echo "Failed to update SHA256 in local formula"
    exit 1
fi

# Commit local changes
echo "Committing local changes..."
git add "$LOCAL_FORMULA_PATH"
git commit --allow-empty -m "Update dopctl to version ${NEW_VERSION}"
git push origin main

# Clone the tap repository if it doesn't exist
if [ ! -d "$TAP_DIR" ]; then
    echo "Cloning tap repository..."
    git clone git@github.com:${TAP_REPO}.git "$TAP_DIR"
fi

cd "$TAP_DIR"

# Update the tap formula
echo "Updating tap formula..."
sed -i '' "s|url \".*\"|url \"https://github.com/${REPO}/archive/v${NEW_VERSION}.tar.gz\"|" "$TAP_FORMULA_PATH"
sed -i '' "s|sha256 \".*\"|sha256 \"${NEW_SHA256}\"|" "$TAP_FORMULA_PATH"

# Verify the tap changes
echo "Verifying tap changes..."
if ! grep -q "sha256 \"${NEW_SHA256}\"" "$TAP_FORMULA_PATH"; then
    echo "Failed to update SHA256 in tap formula"
    exit 1
fi

# Force commit and push changes to tap
echo "Committing and pushing tap changes..."
git add "$TAP_FORMULA_PATH"
git commit --allow-empty -m "Update dopctl to version ${NEW_VERSION}"
git push origin main

# Clean up
echo "Cleaning up..."
cd - > /dev/null
rm -rf "$TAP_DIR"

echo "Formula updated successfully!"
echo "New version: ${NEW_VERSION}"
echo "New SHA256: ${NEW_SHA256}"
echo ""
echo "Changes have been pushed to:"
echo "1. ${REPO} (local formula)"
echo "2. ${TAP_REPO} (tap formula)"
echo ""
echo "The formulas have been updated with:"
echo "- Version: ${NEW_VERSION}"
echo "- URL: https://github.com/${REPO}/archive/v${NEW_VERSION}.tar.gz"
echo "- SHA256: ${NEW_SHA256}" 
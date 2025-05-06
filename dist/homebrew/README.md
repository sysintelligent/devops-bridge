# DevOps CLI Package Management

This directory contains distribution configurations for distributing the DevOps CLI tool via Homebrew.

## Table of Contents
- [Formula Management](#formula-management)
  - [Automated Version Updates](#automated-version-updates)
  - [Manual Formula Updates](#manual-formula-updates)
  - [Testing Locally](#testing-locally)
  - [Using the Custom Tap](#using-the-custom-tap)
- [Current Version](#current-version)

## Formula Management

### Automated Version Updates

The `update_version.sh` script automates the process of updating both the local formula and the Homebrew tap repository. It handles:
- Creating and pushing a new Git tag
- Downloading the release tarball
- Calculating the SHA256 hash
- Updating both local and tap formulas
- Committing and pushing changes

#### Prerequisites
- Git access to both the main repository and the tap repository
- GitHub CLI installed (if using GitHub releases)
- Proper SSH keys configured for GitHub access
- Write permissions to both repositories

#### Error Handling
The script includes several safety checks:
- Verifies the new version is provided
- Checks for existing tags and removes them if necessary
- Retries SHA256 hash calculation up to 5 times
- Verifies formula updates before committing
- Ensures proper cleanup of temporary files

To use the script:
```bash
# Make the script executable (if needed)
chmod +x update_version.sh

# Run the script with the new version number
./update_version.sh 1.0.4
```

The script will:
1. Delete any existing tag for the version
2. Create and push a new tag
3. Wait for GitHub to create the release
4. Calculate the SHA256 hash
5. Update both local and tap formulas
6. Commit and push all changes

### Manual Formula Updates

If you need to update the formula manually:

1. Create a new release on GitHub (e.g., v1.0.2)
2. Calculate the SHA256 hash of the release tarball:
   ```bash
   curl -L https://github.com/sysintelligent/devops-bridge/archive/v1.0.2.tar.gz | shasum -a 256
   ```
3. Update `dopctl.rb` with:
   - New version number in the URL
   - New SHA256 hash

### Testing Locally

Test the formula before pushing to the tap:

```bash
# Install from the local formula
brew install --build-from-source ./dopctl.rb

# Verify installation
dopctl version

# Test the dashboard
dopctl admin dashboard
```

### Using the Custom Tap

The DevOps CLI is distributed through our custom Homebrew tap at [sysintelligent/homebrew-sysintelligent](https://github.com/sysintelligent/homebrew-sysintelligent). To use it:

1. Add the tap to your Homebrew installation:
   ```bash
   brew tap sysintelligent/sysintelligent git@github.com:sysintelligent/homebrew-sysintelligent.git
   ```

2. Install the DevOps CLI:
   ```bash
   brew install sysintelligent/sysintelligent/dopctl
   ```

The `update_version.sh` script automatically updates both the local formula and the tap repository when a new version is released.

## Current Version

The current version can be found in `dopctl.rb`. To check the latest version:
```bash
grep "version" dopctl.rb
```
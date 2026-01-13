#!/bin/bash

# Script to move sink connector submodule to a new GitHub repository
# Uses GitHub CLI (gh) to create the new repo

set -e  # Exit on error

SUBMODULE_PATH="submodules/active_data_flow-connector-sink-json_rpc"
NEW_REPO_NAME="active_data_flow-connector-sink-json_rpc"
TEMP_DIR="/tmp/${NEW_REPO_NAME}"

echo "=== Moving Sink Connector to New Repository ==="
echo ""

# Check if submodule exists
if [ ! -d "$SUBMODULE_PATH" ]; then
    echo "Error: Submodule not found at $SUBMODULE_PATH"
    exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

# Clean temp directory if it exists
rm -rf "$TEMP_DIR"

# Copy submodule content to temp directory
echo "Copying submodule content to temporary directory..."
mkdir -p "$TEMP_DIR"
cp -r "$SUBMODULE_PATH"/* "$TEMP_DIR/" 2>/dev/null || true
cp -r "$SUBMODULE_PATH"/.[!.]* "$TEMP_DIR/" 2>/dev/null || true

# Remove .git directory if it exists (we'll create a fresh repo)
rm -rf "$TEMP_DIR/.git"

# Initialize new git repo
cd "$TEMP_DIR"
echo ""
echo "Initializing new git repository..."
git init
git add .
git commit -m "Initial commit: Move from active_data_flow submodule"

# Create new GitHub repository
echo ""
echo "Creating new GitHub repository: $NEW_REPO_NAME"
gh repo create "$NEW_REPO_NAME" --private --source=. --remote=origin --push

echo ""
echo "=== Success! ==="
echo "New repository created: $(gh repo view --json url -q .url)"
echo ""
echo "=== Next Steps ==="
echo "1. Update the submodule reference in active_data_flow:"
echo "   cd /Users/ericlaquer/Documents/GitHub/active_data_flow"
echo "   git submodule deinit -f $SUBMODULE_PATH"
echo "   git rm -f $SUBMODULE_PATH"
echo "   rm -rf .git/modules/$SUBMODULE_PATH"
echo "   git submodule add <new-repo-url> $SUBMODULE_PATH"
echo ""
echo "2. Or remove the submodule entirely if no longer needed:"
echo "   git submodule deinit -f $SUBMODULE_PATH"
echo "   git rm -f $SUBMODULE_PATH"
echo "   rm -rf .git/modules/$SUBMODULE_PATH"
echo "   git commit -m 'Remove sink connector submodule'"

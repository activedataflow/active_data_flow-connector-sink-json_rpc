#!/bin/bash

# Script to move JSON-RPC connector submodules into the main active_data_flow repository
# This will convert submodules to regular directories and preserve git history

set -e  # Exit on error

REPO_ROOT="/Users/ericlaquer/Documents/GitHub/active_data_flow"
SOURCE_SUBMODULE="submodules/active_data_flow-connector-source-json_rpc"
SINK_SUBMODULE="submodules/active_data_flow-connector-sink-json_rpc"
TARGET_SOURCE_DIR="active_data_flow/connectors/source/json_rpc"
TARGET_SINK_DIR="active_data_flow/connectors/sink/json_rpc"

cd "$REPO_ROOT"

echo "=== Moving JSON-RPC Connectors to Main Repo ==="
echo ""

# Check if submodules exist
if [ ! -d "$SOURCE_SUBMODULE" ] || [ ! -d "$SINK_SUBMODULE" ]; then
    echo "Error: One or both submodules not found"
    echo "Looking for:"
    echo "  - $SOURCE_SUBMODULE"
    echo "  - $SINK_SUBMODULE"
    exit 1
fi

# Create target directories
echo "Creating target directories..."
mkdir -p "$(dirname "$TARGET_SOURCE_DIR")"
mkdir -p "$(dirname "$TARGET_SINK_DIR")"

# Remove submodule entries from .gitmodules and git config
echo ""
echo "Removing submodule configurations..."

if [ -f .gitmodules ]; then
    # Remove source connector submodule
    git config -f .gitmodules --remove-section "submodule.$SOURCE_SUBMODULE" 2>/dev/null || true
    git config --remove-section "submodule.$SOURCE_SUBMODULE" 2>/dev/null || true
    
    # Remove sink connector submodule
    git config -f .gitmodules --remove-section "submodule.$SINK_SUBMODULE" 2>/dev/null || true
    git config --remove-section "submodule.$SINK_SUBMODULE" 2>/dev/null || true
    
    # Clean up .gitmodules if empty
    if [ ! -s .gitmodules ]; then
        rm .gitmodules
        git rm .gitmodules 2>/dev/null || true
    else
        git add .gitmodules
    fi
fi

# Remove submodules from git index
echo "Removing submodules from git index..."
git rm --cached "$SOURCE_SUBMODULE" 2>/dev/null || true
git rm --cached "$SINK_SUBMODULE" 2>/dev/null || true

# Remove .git directories from submodules (convert to regular directories)
echo "Converting submodules to regular directories..."
rm -rf "$SOURCE_SUBMODULE/.git"
rm -rf "$SINK_SUBMODULE/.git"

# Move content to new locations
echo ""
echo "Moving source connector: $SOURCE_SUBMODULE -> $TARGET_SOURCE_DIR"
mv "$SOURCE_SUBMODULE"/* "$TARGET_SOURCE_DIR/" 2>/dev/null || true
mv "$SOURCE_SUBMODULE"/.[!.]* "$TARGET_SOURCE_DIR/" 2>/dev/null || true

echo "Moving sink connector: $SINK_SUBMODULE -> $TARGET_SINK_DIR"
mv "$SINK_SUBMODULE"/* "$TARGET_SINK_DIR/" 2>/dev/null || true
mv "$SINK_SUBMODULE"/.[!.]* "$TARGET_SINK_DIR/" 2>/dev/null || true

# Remove empty submodule directories
echo "Cleaning up old submodule directories..."
rmdir "$SOURCE_SUBMODULE" 2>/dev/null || true
rmdir "$SINK_SUBMODULE" 2>/dev/null || true
rmdir "submodules" 2>/dev/null || true

# Stage the new files
echo ""
echo "Staging new connector files..."
git add "$TARGET_SOURCE_DIR"
git add "$TARGET_SINK_DIR"

# Show status
echo ""
echo "=== Changes staged ==="
git status

echo ""
echo "=== Next Steps ==="
echo "1. Review the changes above"
echo "2. Commit with: git commit -m 'Move JSON-RPC connectors from submodules to main repo'"
echo "3. Push to remote: git push"
echo ""
echo "Optional: Archive old submodule repositories with:"
echo "  gh repo archive ericlaquer/active_data_flow-connector-source-json_rpc"
echo "  gh repo archive ericlaquer/active_data_flow-connector-sink-json_rpc"

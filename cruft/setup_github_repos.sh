#!/bin/bash

# Setup GitHub repositories for Sinatra examples
# This script initializes Git repositories and pushes them to GitHub

set -e

echo "=== Setting up GitHub repositories for Sinatra examples ==="

# Function to setup a repository
setup_repo() {
    local repo_name=$1
    local repo_path=$2
    local description=$3
    
    echo ""
    echo "Setting up repository: $repo_name"
    echo "Path: $repo_path"
    echo "Description: $description"
    
    cd "$repo_path"
    
    # Initialize git if not already initialized
    if [ ! -d ".git" ]; then
        echo "Initializing Git repository..."
        git init
        git branch -M main
    fi
    
    # Add all files
    echo "Adding files to Git..."
    git add .
    
    # Create initial commit
    echo "Creating initial commit..."
    git commit -m "Initial commit: $description" || echo "No changes to commit"
    
    # Add remote origin
    echo "Adding remote origin..."
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/magenticmarketactualskill/$repo_name.git"
    
    echo "Repository $repo_name is ready to push to GitHub"
    echo "Run: cd $repo_path && git push -u origin main"
    
    cd - > /dev/null
}

# Setup sinatra-json-rpc-demo
setup_repo "sinatra-json-rpc-demo" \
           "$(pwd)/sinatra-json-rpc-demo" \
           "A demonstration project showcasing JSON-RPC 2.0 communication between two Sinatra applications"

# Setup sinatra-json-rpc-ld
setup_repo "sinatra-json-rpc-ld" \
           "$(pwd)/sinatra-json-rpc-ld" \
           "A demonstration project showcasing JSON-RPC communication enhanced with JSON-LD (Linked Data) capabilities"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Create the repositories on GitHub:"
echo "   - https://github.com/magenticmarketactualskill/sinatra-json-rpc-demo"
echo "   - https://github.com/magenticmarketactualskill/sinatra-json-rpc-ld"
echo ""
echo "2. Push the repositories:"
echo "   cd sinatra-json-rpc-demo && git push -u origin main"
echo "   cd sinatra-json-rpc-ld && git push -u origin main"
echo ""
echo "3. Update the parent repository to reference these as submodules if needed"
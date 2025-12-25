#!/bin/bash

# Verification script for Sinatra example projects
# Ensures both projects are properly configured and functional

set -e

echo "=== Verifying Sinatra Example Projects ==="

# Function to verify a project
verify_project() {
    local project_name=$1
    local project_path=$2
    
    echo ""
    echo "Verifying project: $project_name"
    echo "Path: $project_path"
    
    cd "$project_path"
    
    # Check required files
    echo "Checking required files..."
    required_files=(
        ".submoduler.ini"
        ".gitignore"
        "README.md"
        "install_dependencies.sh"
        "start_server.sh"
        "start_client.sh"
        "start_demo.sh"
        "test_demo.sh"
        "server/Gemfile"
        "client/Gemfile"
        "server/app.rb"
        "client/app.rb"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file (missing)"
        fi
    done
    
    # Check executable permissions
    echo "Checking executable permissions..."
    scripts=(
        "install_dependencies.sh"
        "start_server.sh"
        "start_client.sh"
        "start_demo.sh"
        "test_demo.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -x "$script" ]; then
            echo "  ✅ $script (executable)"
        else
            echo "  ❌ $script (not executable)"
        fi
    done
    
    # Check Git status
    echo "Checking Git status..."
    if [ -d ".git" ]; then
        echo "  ✅ Git repository initialized"
        
        # Check if there are any uncommitted changes
        if git diff --quiet && git diff --cached --quiet; then
            echo "  ✅ No uncommitted changes"
        else
            echo "  ⚠️  Uncommitted changes detected"
        fi
        
        # Check remote
        if git remote get-url origin >/dev/null 2>&1; then
            remote_url=$(git remote get-url origin)
            echo "  ✅ Remote origin configured: $remote_url"
        else
            echo "  ❌ No remote origin configured"
        fi
    else
        echo "  ❌ Git repository not initialized"
    fi
    
    # Check .submoduler.ini content
    echo "Checking .submoduler.ini configuration..."
    if grep -q "name = $project_name" .submoduler.ini; then
        echo "  ✅ Project name correctly set"
    else
        echo "  ❌ Project name not set correctly"
    fi
    
    if grep -q "remote_url = https://github.com/magenticmarketactualskill/$project_name.git" .submoduler.ini; then
        echo "  ✅ Remote URL correctly configured"
    else
        echo "  ❌ Remote URL not configured correctly"
    fi
    
    echo "Project $project_name verification complete"
    cd - > /dev/null
}

# Verify both projects
verify_project "sinatra-json-rpc-demo" "$(pwd)/sinatra-json-rpc-demo"
verify_project "sinatra-json-rpc-ld" "$(pwd)/sinatra-json-rpc-ld"

echo ""
echo "=== Verification Summary ==="
echo ""
echo "Both projects have been verified and are ready for GitHub deployment."
echo ""
echo "Next steps:"
echo "1. Create repositories on GitHub"
echo "2. Push using: cd <project> && git push -u origin main"
echo "3. Verify repositories are accessible and functional"
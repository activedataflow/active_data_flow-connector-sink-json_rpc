#!/bin/bash

# Rails 8 JSON-RPC Demo Setup Script
# This script sets up both applications with databases and dependencies

echo "Setting up Rails 8 JSON-RPC Demo..."
echo "==================================="

# Setup server app
echo "Setting up ServerApp..."
cd server_app
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
cd ..

# Setup client app
echo "Setting up ClientApp..."
cd client_app
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
cd ..

echo ""
echo "Setup complete!"
echo "==============="
echo "Run './start_demo.sh' to start both applications"
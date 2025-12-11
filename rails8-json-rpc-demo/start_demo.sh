#!/bin/bash

# Rails 8 JSON-RPC Demo Startup Script
# This script starts both the server and client applications

echo "Starting Rails 8 JSON-RPC Demo..."
echo "================================="

# Function to cleanup background processes on exit
cleanup() {
    echo "Shutting down applications..."
    kill $SERVER_PID $CLIENT_PID 2>/dev/null
    exit
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start server app on port 3000
echo "Starting ServerApp on port 3000..."
cd server_app
bundle install --quiet
bundle exec rails server -p 3000 &
SERVER_PID=$!
cd ..

# Wait a moment for server to start
sleep 3

# Start client app on port 3001
echo "Starting ClientApp on port 3001..."
cd client_app
bundle install --quiet
bundle exec rails server -p 3001 &
CLIENT_PID=$!
cd ..

echo ""
echo "Demo applications started!"
echo "========================="
echo "ServerApp: http://localhost:3000"
echo "ClientApp: http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop both applications"

# Wait for background processes
wait $SERVER_PID $CLIENT_PID
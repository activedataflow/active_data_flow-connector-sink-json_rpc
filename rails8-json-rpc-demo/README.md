# Rails 8 JSON-RPC Demo

This demo showcases ActiveDataFlow JSON-RPC connector usage in Rails 8 applications. It consists of two Rails applications:

- **ServerApp** (port 3000): Receives data via ActiveDataFlow JSON-RPC source connector
- **ClientApp** (port 3001): Sends data via ActiveDataFlow JSON-RPC sink connector

## Quick Start

1. **Setup**: Run the setup script to install dependencies and create databases
   ```bash
   ./setup_demo.sh
   ```

2. **Start**: Run both applications simultaneously
   ```bash
   ./start_demo.sh
   ```

3. **Access**:
   - ServerApp: http://localhost:3000
   - ClientApp: http://localhost:3001

## Architecture

The demo demonstrates:
- ActiveDataFlow engine integration in Rails 8
- JSON-RPC communication between Rails applications
- Heartbeat-based DataFlow execution
- Web interfaces for monitoring and data management
- Proper error handling and logging

## Applications

### ServerApp (Port 3000)
- Uses `ActiveDataFlow::Connector::Source::JsonRpcSource` to receive data
- Stores received data in `ReceivedRecord` model
- Provides web interface to monitor received data and DataFlow status

### ClientApp (Port 3001)
- Uses `ActiveDataFlow::Connector::Sink::JsonRpcSink` to send data
- Reads from `OutgoingRecord`, `User`, and `Order` models
- Provides web forms for creating data and monitoring sends

## DataFlow Configuration

Both applications use ActiveDataFlow with:
- Heartbeat runtime for scheduled execution (30-second intervals)
- JSON-RPC connectors for communication
- ActiveRecord connectors for database operations
- Proper error handling and retry logic

## Development

- Each application is a standard Rails 8 application
- Separate SQLite databases simulate distributed setup
- ActiveDataFlow engine mounted at `/active_data_flow`
- Bootstrap 5 for UI styling

## Stopping

Press `Ctrl+C` in the terminal running `start_demo.sh` to stop both applications.
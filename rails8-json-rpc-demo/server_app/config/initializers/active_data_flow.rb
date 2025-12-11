# ActiveDataFlow configuration for ServerApp

ActiveDataFlow.configure do |config|
  # Configure logging
  config.log_level = :info
  
  # Use ActiveRecord storage backend
  config.storage_backend = :active_record
  
  # Auto-load DataFlows
  config.auto_load_data_flows = true
  config.data_flows_path = "app/data_flows"
end

# Register DataFlows after initialization
Rails.application.config.after_initialize do
  # Setup the JSON-RPC to Database DataFlow
  begin
    JsonRpcToDatabaseFlow.setup_flow
    Rails.logger.info "Setup JsonRpcToDatabaseFlow"
  rescue => e
    Rails.logger.error "Failed to setup JsonRpcToDatabaseFlow: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
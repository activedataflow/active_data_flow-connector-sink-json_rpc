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
  # DataFlows will be registered when they are defined
end
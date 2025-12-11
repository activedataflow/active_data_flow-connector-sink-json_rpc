# JSON-RPC configuration for ClientApp

# Configure JSON-RPC client settings
Rails.application.configure do
  # JSON-RPC client configuration
  config.json_rpc_client = {
    server_url: ENV.fetch('JSON_RPC_SERVER_URL', 'http://localhost:8999'),
    timeout: ENV.fetch('JSON_RPC_TIMEOUT', 30).to_i,
    
    # Retry configuration
    retry_attempts: ENV.fetch('JSON_RPC_RETRY_ATTEMPTS', 3).to_i,
    retry_delay: ENV.fetch('JSON_RPC_RETRY_DELAY', 5).to_i, # seconds
    retry_backoff: ENV.fetch('JSON_RPC_RETRY_BACKOFF', 'exponential'), # linear or exponential
    
    # Batch processing
    batch_size: ENV.fetch('JSON_RPC_BATCH_SIZE', 10).to_i,
    
    # Connection settings
    connection_pool_size: ENV.fetch('JSON_RPC_POOL_SIZE', 5).to_i,
    
    # Logging
    log_requests: Rails.env.development?,
    log_responses: Rails.env.development?
  }
end
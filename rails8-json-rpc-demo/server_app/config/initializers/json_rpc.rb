# JSON-RPC configuration for ServerApp

# Configure JSON-RPC server settings
Rails.application.configure do
  # JSON-RPC server configuration
  config.json_rpc_server = {
    host: ENV.fetch('JSON_RPC_HOST', '0.0.0.0'),
    port: ENV.fetch('JSON_RPC_PORT', 8999).to_i,
    timeout: ENV.fetch('JSON_RPC_TIMEOUT', 30).to_i,
    max_connections: ENV.fetch('JSON_RPC_MAX_CONNECTIONS', 10).to_i,
    
    # Security settings
    allowed_origins: ENV.fetch('JSON_RPC_ALLOWED_ORIGINS', 'localhost,127.0.0.1').split(','),
    
    # Logging
    log_requests: Rails.env.development?,
    log_responses: Rails.env.development?
  }
end
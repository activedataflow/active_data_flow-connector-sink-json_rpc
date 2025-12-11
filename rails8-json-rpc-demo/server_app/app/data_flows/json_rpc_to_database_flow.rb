class JsonRpcToDatabaseFlow < ActiveDataFlow::DataFlow
  # This class represents a DataFlow that receives JSON-RPC data and stores it in the database
  
  def self.setup_flow
    # Create or update the DataFlow record in the database
    ActiveDataFlow::DataFlow.find_or_create(
      name: "json_rpc_to_database",
      source: configure_source,
      sink: configure_sink,
      runtime: configure_runtime
    )
  end

  private

  def self.configure_source
    # This would be the JSON-RPC source connector configuration
    # For now, we'll create a placeholder since the actual connectors need more setup
    {
      class_name: "ActiveDataFlow::Connector::Source::JsonRpcSource",
      host: '0.0.0.0',
      port: 8999,
      timeout: 30,
      max_connections: 10
    }
  end

  def self.configure_sink
    # ActiveRecord sink configuration
    {
      class_name: "ActiveDataFlow::Connector::Sink::ActiveRecordSink",
      model_class: "ReceivedRecord",
      batch_size: 10
    }
  end

  def self.configure_runtime
    # Heartbeat runtime configuration
    {
      class_name: "ActiveDataFlow::Runtime::Heartbeat",
      interval: 30, # seconds
      enabled: true
    }
  end

  # Override the transform method for this specific DataFlow
  def transform(record)
    Rails.logger.info "Transforming JSON-RPC record: #{record.inspect}"
    
    # Transform the incoming JSON-RPC record to ReceivedRecord format
    {
      record_type: record['type'] || 'unknown',
      source_id: record['id'] || 0,
      data: record,
      received_at: Time.current
    }
  end

  def after_write(records)
    Rails.logger.info "Successfully stored #{records.size} records from JSON-RPC"
    
    # Mark records as processed after successful write
    record_ids = records.map { |r| r.id }
    ReceivedRecord.where(id: record_ids).update_all(processed_at: Time.current)
  end

  def on_error(error, record = nil)
    Rails.logger.error "JSON-RPC DataFlow error: #{error.message}"
    Rails.logger.error "Record: #{record.inspect}" if record
    Rails.logger.error error.backtrace.join("\n")
  end
end
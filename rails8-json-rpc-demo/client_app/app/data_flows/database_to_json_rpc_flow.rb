class DatabaseToJsonRpcFlow < ActiveDataFlow::DataFlow
  # This class represents a DataFlow that reads from database and sends via JSON-RPC
  
  def self.setup_flow
    # Create or update the DataFlow record in the database
    ActiveDataFlow::DataFlow.find_or_create(
      name: "database_to_json_rpc",
      source: configure_source,
      sink: configure_sink,
      runtime: configure_runtime
    )
  end

  private

  def self.configure_source
    # ActiveRecord source configuration
    {
      class_name: "ActiveDataFlow::Connector::Source::ActiveRecordSource",
      model_class: "OutgoingRecord",
      scope: "pending",
      batch_size: 10
    }
  end

  def self.configure_sink
    # JSON-RPC sink configuration
    {
      class_name: "ActiveDataFlow::Connector::Sink::JsonRpcSink",
      url: 'http://localhost:8999',
      batch_size: 10,
      timeout: 30,
      retry_attempts: 3
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
  def transform(outgoing_record)
    Rails.logger.info "Transforming outgoing record: #{outgoing_record.id}"
    
    # Transform OutgoingRecord to format expected by JSON-RPC server
    data = outgoing_record.data.dup
    data.merge!(
      'id' => outgoing_record.id,
      'type' => outgoing_record.record_type,
      'sent_from' => 'client_app',
      'timestamp' => Time.current.iso8601
    )
    
    # Store reference to original record for after_write callback
    data['_outgoing_record_id'] = outgoing_record.id
    
    data
  end

  def after_write(records)
    Rails.logger.info "Successfully sent #{records.size} records via JSON-RPC"
    
    # Mark records as sent after successful transmission
    record_ids = records.map { |r| r['_outgoing_record_id'] }.compact
    OutgoingRecord.where(id: record_ids).find_each do |record|
      record.mark_as_sent!
    end
  end

  def on_error(error, record = nil)
    Rails.logger.error "JSON-RPC DataFlow error: #{error.message}"
    Rails.logger.error "Record: #{record.inspect}" if record
    Rails.logger.error error.backtrace.join("\n")
    
    # Mark record as failed if we have the record reference
    if record && record['_outgoing_record_id']
      outgoing_record = OutgoingRecord.find_by(id: record['_outgoing_record_id'])
      outgoing_record&.mark_as_failed!(error.message)
    end
  end
end
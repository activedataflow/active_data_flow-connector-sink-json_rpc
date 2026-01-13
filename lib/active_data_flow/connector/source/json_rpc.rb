# frozen_string_literal: true

require 'active_data_flow/connector/json_rpc'
require 'active_data_flow/connector/source/base'

module ActiveDataFlow
  module Connector
    module Source
      # JSON-RPC Source Connector
      # Receives data via JSON-RPC server and provides it as a source for data flows
      class JsonRpcSource < ::ActiveDataFlow::Connector::Source::Base
        attr_reader :host, :port, :handler, :server, :server_thread

        # Initialize a new JSON-RPC source
        # @param host [String] The host to bind the server to (default: '0.0.0.0')
        # @param port [Integer] The port to bind the server to (default: 8999)
        # @param handler_class [Class] Custom handler class (optional)
        def initialize(host: '0.0.0.0', port: 8999, handler_class: nil)
          @host = host
          @port = port
          @handler_class = handler_class || ActiveDataFlow::Connector::JsonRpc::ServerHandler
          @handler = @handler_class.new
          @server = nil
          @server_thread = nil
          @running = false

          # Store serializable representation
          super(
            host: host,
            port: port,
            handler_class: handler_class&.name
          )
        end

        # Start the JSON-RPC server
        # @return [void]
        def start_server
          return if @running

          @server = Jimson::Server.new(@handler, host: @host, port: @port)
          @server_thread = Thread.new do
            begin
              @server.start
            rescue => e
              Rails.logger.error("JSON-RPC Server error: #{e.message}") if defined?(Rails)
              puts "JSON-RPC Server error: #{e.message}"
            end
          end

          @running = true

          # Give server time to start
          sleep 0.5
        end

        # Stop the JSON-RPC server
        # @return [void]
        def stop_server
          return unless @running

          @server&.stop
          @server_thread&.kill
          @running = false
        end

        # Check if server is running
        # @return [Boolean]
        def running?
          @running
        end

        # Iterate through received records
        # @param batch_size [Integer] Number of records to process per batch
        # @param start_id [Integer, nil] Starting ID for cursor-based pagination (not used for JSON-RPC)
        # @yield [record] Each record received via JSON-RPC
        def each(batch_size:, start_id: nil, &block)
          start_server unless running?

          loop do
            records = []

            # Collect records up to batch_size
            batch_size.times do
              if @handler.has_records?
                record = @handler.next_record
                records << record if record
              else
                # Wait a bit for new records if we haven't collected any
                sleep 0.1 if records.empty?
                break
              end
            end

            # Yield each record
            records.each(&block) if records.any?

            # Break if no records were collected (allows for graceful shutdown)
            break if records.empty? && !running?
          end
        end

        # Close the source and clean up resources
        # @return [void]
        def close
          stop_server
        end

        # Deserialize from JSON
        # @param data [Hash] Serialized data
        # @return [JsonRpcSource] New instance
        def self.from_json(data)
          handler_class = data["handler_class"] ? Object.const_get(data["handler_class"]) : nil

          new(
            host: data["host"],
            port: data["port"],
            handler_class: handler_class
          )
        end

        # Get server URL
        # @return [String] The server URL
        def server_url
          "http://#{host}:#{port}"
        end

        # Get current queue size
        # @return [Integer] Number of queued records
        def queue_size
          @handler.drain_queue.tap { |records|
            records.each { |r| @handler.receive_record(r) }
          }.size
        end
      end
    end
  end
end

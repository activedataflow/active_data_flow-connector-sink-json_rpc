# frozen_string_literal: true

require 'active_data_flow/connector/json_rpc'
require 'active_data_flow/connector/sink/base'

module ActiveDataFlow
  module Connector
    module Sink
      # JSON-RPC Sink Connector
      # Sends data via JSON-RPC client to a remote server
      class JsonRpcSink < ::ActiveDataFlow::Connector::Sink::Base
        attr_reader :url, :batch_size, :client_wrapper

        # Initialize a new JSON-RPC sink
        # @param url [String] The JSON-RPC server URL
        # @param batch_size [Integer] Number of records to batch before sending (default: 100)
        # @param client_options [Hash] Additional options for the Jimson client
        def initialize(url:, batch_size: 100, client_options: {})
          @url = url
          @batch_size = batch_size
          @client_options = client_options
          @client_wrapper = ActiveDataFlow::Connector::JsonRpc::ClientWrapper.new(
            url: url,
            options: client_options
          )
          @buffer = []
          @mutex = Mutex.new

          # Store serializable representation
          super(
            url: url,
            batch_size: batch_size,
            client_options: client_options
          )
        end

        # Write a single record to the JSON-RPC server
        # @param record [Hash] The record to send
        # @return [Hash] Response from server
        def write(record)
          response = @client_wrapper.send_record(record)

          if response[:status] == 'error'
            handle_write_error(response, record)
          end

          response
        end

        # Write multiple records to the JSON-RPC server
        # @param records [Array<Hash>] The records to send
        # @return [Hash] Response from server
        def write_batch(records)
          return { status: 'success', message: 'No records to write' } if records.empty?

          response = @client_wrapper.send_records(records)

          if response[:status] == 'error'
            handle_batch_error(response, records)
          end

          response
        end

        # Buffer a record and flush when batch size is reached
        # @param record [Hash] The record to buffer
        # @return [Hash, nil] Response if buffer was flushed, nil otherwise
        def buffer_write(record)
          @mutex.synchronize do
            @buffer << record

            if @buffer.size >= @batch_size
              records = @buffer.dup
              @buffer.clear
              return write_batch(records)
            end
          end

          nil
        end

        # Flush any buffered records
        # @return [Hash, nil] Response from server or nil if buffer was empty
        def flush
          records = nil

          @mutex.synchronize do
            return nil if @buffer.empty?
            records = @buffer.dup
            @buffer.clear
          end

          write_batch(records)
        end

        # Close the sink and flush any remaining records
        # @return [void]
        def close
          flush
        end

        # Test connection to the server
        # @return [Boolean] True if connection is successful
        def test_connection
          @client_wrapper.test_connection
        end

        # Get server health status
        # @return [Hash] Health status from server
        def health_check
          @client_wrapper.health_check
        end

        # Get current buffer size
        # @return [Integer] Number of buffered records
        def buffer_size
          @mutex.synchronize { @buffer.size }
        end

        # Deserialize from JSON
        # @param data [Hash] Serialized data
        # @return [JsonRpcSink] New instance
        def self.from_json(data)
          new(
            url: data["url"],
            batch_size: data["batch_size"],
            client_options: data["client_options"] || {}
          )
        end

        private

        # Handle errors when writing a single record
        # @param response [Hash] Error response
        # @param record [Hash] The record that failed
        def handle_write_error(response, record)
          error_message = "Failed to write record: #{response[:message]}"

          if defined?(Rails)
            Rails.logger.error(error_message)
            Rails.logger.error("Record: #{record.inspect}")
          else
            puts error_message
            puts "Record: #{record.inspect}"
          end
        end

        # Handle errors when writing a batch
        # @param response [Hash] Error response
        # @param records [Array<Hash>] The records that failed
        def handle_batch_error(response, records)
          error_message = "Failed to write batch: #{response[:message]}"

          if defined?(Rails)
            Rails.logger.error(error_message)
            Rails.logger.error("Failed records count: #{records.size}")
          else
            puts error_message
            puts "Failed records count: #{records.size}"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "active_data_flow/connector/json_rpc"
require "active_data_flow/connector/sink/base"
require "active_data_flow/connector/sink/buffer"

module ActiveDataFlow
  module Connector
    module Sink
      # JSON-RPC Sink Connector
      # Sends data via JSON-RPC client to a remote server
      class JsonRpcSink < ::ActiveDataFlow::Connector::Sink::Base
        include ActiveDataFlow::Result

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
          @buffer = Buffer.new(batch_size: batch_size)

          # Store serializable representation
          super(
            url: url,
            batch_size: batch_size,
            client_options: client_options
          )
        end

        # Write a single record to the JSON-RPC server
        #
        # @param record [Hash] The record to send
        # @return [Dry::Monads::Result] Success(response) or Failure[:rpc_error, {...}]
        def write(record)
          result = @client_wrapper.send_record(record)

          result.or do |failure|
            log_write_error(failure, record)
            result
          end
        end

        # Write multiple records to the JSON-RPC server
        #
        # @param records [Array<Hash>] The records to send
        # @return [Dry::Monads::Result] Success(response) or Failure[:rpc_error, {...}]
        def write_batch(records)
          return Success({ status: "success", message: "No records to write" }) if records.empty?

          result = @client_wrapper.send_records(records)

          result.or do |failure|
            log_batch_error(failure, records)
            result
          end
        end

        # Buffer a record and flush when batch size is reached
        #
        # @param record [Hash] The record to buffer
        # @return [Dry::Monads::Result, nil] Result if buffer was flushed, nil otherwise
        def buffer_write(record)
          @buffer.add(record) { |records| write_batch(records) }
        end

        # Flush any buffered records
        #
        # @return [Dry::Monads::Result, nil] Result or nil if buffer was empty
        def flush
          @buffer.flush { |records| write_batch(records) }
        end

        # Close the sink and flush any remaining records
        #
        # @return [Dry::Monads::Result, nil]
        def close
          flush
        end

        # Test connection to the server
        #
        # @return [Dry::Monads::Result] Success(true) or Failure[:rpc_error, {...}]
        def test_connection
          @client_wrapper.test_connection
        end

        # Get server health status
        #
        # @return [Dry::Monads::Result] Success(response) or Failure[:rpc_error, {...}]
        def health_check
          @client_wrapper.health_check
        end

        # Get current buffer size
        #
        # @return [Integer] Number of buffered records
        def buffer_size
          @buffer.size
        end

        # Deserialize from JSON
        #
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

        # Log errors when writing a single record
        #
        # @param failure [Array] The failure data [type, details]
        # @param record [Hash] The record that failed
        def log_write_error(failure, record)
          _type, details = failure
          error_message = "Failed to write record: #{details[:message]}"

          if defined?(Rails)
            Rails.logger.error(error_message)
            Rails.logger.error("Record: #{record.inspect}")
          else
            puts error_message
            puts "Record: #{record.inspect}"
          end
        end

        # Log errors when writing a batch
        #
        # @param failure [Array] The failure data [type, details]
        # @param records [Array<Hash>] The records that failed
        def log_batch_error(failure, records)
          _type, details = failure
          error_message = "Failed to write batch: #{details[:message]}"

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

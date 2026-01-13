# frozen_string_literal: true

require 'jimson'

module ActiveDataFlow
  module Connector
    module JsonRpc
      # Wrapper for Jimson::Client with common functionality
      # Provides helper methods for sending data via JSON-RPC
      class ClientWrapper
        attr_reader :url, :client

        # Initialize a new JSON-RPC client
        # @param url [String] The JSON-RPC server URL
        # @param options [Hash] Additional client options
        def initialize(url:, options: {})
          @url = url
          @client = Jimson::Client.new(url, options)
        end

        # Send a single record via JSON-RPC
        # @param record [Hash] The record data
        # @return [Hash] Response from server
        def send_record(record)
          client.receive_record(record)
        rescue StandardError => e
          handle_error(e, record)
        end

        # Send multiple records via JSON-RPC
        # @param records [Array<Hash>] Array of record data
        # @return [Hash] Response from server
        def send_records(records)
          client.receive_records(records)
        rescue StandardError => e
          handle_error(e, records)
        end

        # Check server health
        # @return [Hash] Server health status
        def health_check
          client.health
        rescue StandardError => e
          { status: 'error', message: e.message }
        end

        # Test connection to server
        # @return [Boolean] True if connection is successful
        def test_connection
          response = health_check
          response[:status] == 'ok'
        rescue StandardError
          false
        end

        private

        # Handle errors during RPC calls
        # @param error [StandardError] The error that occurred
        # @param data [Object] The data that failed to send
        # @return [Hash] Error response
        def handle_error(error, data)
          {
            status: 'error',
            message: error.message,
            error_class: error.class.name,
            data_size: data.is_a?(Array) ? data.size : 1
          }
        end
      end
    end
  end
end

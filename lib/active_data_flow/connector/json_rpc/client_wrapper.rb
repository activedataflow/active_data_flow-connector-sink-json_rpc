# frozen_string_literal: true

require "jimson"

module ActiveDataFlow
  module Connector
    module JsonRpc
      # Wrapper for Jimson::Client with common functionality
      # Provides helper methods for sending data via JSON-RPC
      class ClientWrapper
        include ActiveDataFlow::Result

        attr_reader :url, :client

        # Initialize a new JSON-RPC client
        # @param url [String] The JSON-RPC server URL
        # @param options [Hash] Additional client options
        def initialize(url:, options: {})
          @url = url
          @client = Jimson::Client.new(url, options)
        end

        # Send a single record via JSON-RPC
        #
        # @param record [Hash] The record data
        # @return [Dry::Monads::Result] Success(response) or Failure[:rpc_error, {...}]
        def send_record(record)
          response = client.receive_record(record)
          Success(response)
        rescue StandardError => e
          Failure[:rpc_error, {
            message: e.message,
            exception_class: e.class.name,
            data_size: 1,
            url: url
          }]
        end

        # Send multiple records via JSON-RPC
        #
        # @param records [Array<Hash>] Array of record data
        # @return [Dry::Monads::Result] Success(response) or Failure[:rpc_error, {...}]
        def send_records(records)
          response = client.receive_records(records)
          Success(response)
        rescue StandardError => e
          Failure[:rpc_error, {
            message: e.message,
            exception_class: e.class.name,
            data_size: records.size,
            url: url
          }]
        end

        # Check server health
        #
        # @return [Dry::Monads::Result] Success(response) or Failure[:rpc_error, {...}]
        def health_check
          response = client.health
          Success(response)
        rescue StandardError => e
          Failure[:rpc_error, {
            message: e.message,
            exception_class: e.class.name,
            url: url
          }]
        end

        # Test connection to server
        #
        # @return [Dry::Monads::Result] Success(true) or Failure[:rpc_error, {...}]
        def test_connection
          health_check.bind do |response|
            if response[:status] == "ok"
              Success(true)
            else
              Failure[:rpc_error, {
                message: "Health check returned non-ok status: #{response[:status]}",
                response: response,
                url: url
              }]
            end
          end
        end
      end
    end
  end
end

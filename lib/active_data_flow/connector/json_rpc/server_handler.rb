# frozen_string_literal: true

require 'jimson'

module ActiveDataFlow
  module Connector
    module JsonRpc
      # Base class for JSON-RPC server handlers
      # Provides common functionality for receiving RPC calls
      class ServerHandler
        extend Jimson::Handler

        def initialize
          @queue = Queue.new
        end

        # Receive a single record via JSON-RPC
        # @param record [Hash] The record data
        # @return [Hash] Success response
        def receive_record(record)
          @queue.push(record)
          { status: 'success', message: 'Record received' }
        end

        # Receive multiple records via JSON-RPC
        # @param records [Array<Hash>] Array of record data
        # @return [Hash] Success response
        def receive_records(records)
          records.each { |record| @queue.push(record) }
          { status: 'success', message: "#{records.size} records received" }
        end

        # Check if there are queued records
        # @return [Boolean]
        def has_records?
          !@queue.empty?
        end

        # Get the next record from the queue (non-blocking)
        # @return [Hash, nil] The next record or nil if queue is empty
        def next_record
          @queue.pop(true) rescue nil
        end

        # Get all queued records
        # @return [Array<Hash>] All queued records
        def drain_queue
          records = []
          records << @queue.pop(true) while !@queue.empty?
          records
        rescue ThreadError
          records
        end

        # Health check endpoint
        # @return [Hash] Server status
        def health
          {
            status: 'ok',
            queue_size: @queue.size,
            timestamp: Time.now.iso8601
          }
        end

        protected

        attr_reader :queue
      end
    end
  end
end

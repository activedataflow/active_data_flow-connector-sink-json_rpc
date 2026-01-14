# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Sink
      # Thread-safe buffer for batching records before writing.
      # Used by sinks that support batch operations.
      class Buffer
        attr_reader :batch_size

        # Initialize a new buffer.
        #
        # @param batch_size [Integer] Number of records to collect before flushing
        def initialize(batch_size:)
          @batch_size = batch_size
          @records = []
          @mutex = Mutex.new
        end

        # Add a record to the buffer.
        # Returns the records to flush if batch size is reached, nil otherwise.
        #
        # @param record [Hash] The record to buffer
        # @yield [Array<Hash>] Block called with records when batch is ready
        # @return [Object, nil] Result of block if flushed, nil otherwise
        def add(record, &block)
          records_to_flush = nil

          @mutex.synchronize do
            @records << record

            if @records.size >= @batch_size
              records_to_flush = @records.dup
              @records.clear
            end
          end

          block.call(records_to_flush) if records_to_flush && block_given?
        end

        # Flush all buffered records.
        #
        # @yield [Array<Hash>] Block called with records to flush
        # @return [Object, nil] Result of block if records exist, nil if empty
        def flush(&block)
          records_to_flush = nil

          @mutex.synchronize do
            return nil if @records.empty?

            records_to_flush = @records.dup
            @records.clear
          end

          block.call(records_to_flush) if block_given?
        end

        # Get current buffer size.
        #
        # @return [Integer] Number of buffered records
        def size
          @mutex.synchronize { @records.size }
        end

        # Check if buffer is empty.
        #
        # @return [Boolean]
        def empty?
          @mutex.synchronize { @records.empty? }
        end

        # Check if buffer is full.
        #
        # @return [Boolean]
        def full?
          @mutex.synchronize { @records.size >= @batch_size }
        end
      end
    end
  end
end

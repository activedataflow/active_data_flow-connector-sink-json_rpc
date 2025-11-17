# frozen_string_literal: true

module ActiveDataFlow
  # Test helpers for testing DataFlows
  module TestHelpers
    # Simple in-memory source for testing
    class TestSource < Source
      def self.configuration_attributes
        {
          data: { type: :array, optional: false }
        }
      end

      def each(&block)
        configuration[:data].each do |item|
          message = Message::Unconstrained.new(item)
          block.call(message)
        end
      end
    end

    # Simple sink that collects messages in an array
    class TestSink < Sink
      attr_reader :messages

      def initialize(configuration = {})
        super
        @messages = []
      end

      def write(message)
        @messages << message
      end

      def clear
        @messages.clear
      end
    end

    # Minimal DataFlow implementation for testing
    class TestDataFlow
      include DataFlow

      def self.configuration_attributes
        {
          source: { type: :hash, optional: false },
          sink: { type: :hash, optional: false }
        }
      end

      def run
        source = TestSource.new(configuration[:source])
        sink = TestSink.new(configuration[:sink])

        source.each do |message|
          sink.write(message)
        end

        sink
      end
    end
  end
end

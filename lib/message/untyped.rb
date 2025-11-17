# frozen_string_literal: true

module ActiveDataflow
  module Message
    # Untyped message for flexible data handling
    # Allows passing arbitrary data between sources, transforms, and sinks
    class Untyped
      attr_reader :data, :metadata

      def initialize(data, metadata: {})
        @data = data
        @metadata = metadata
      end

      def [](key)
        data[key]
      end

      def []=(key, value)
        data[key] = value
      end

      def to_h
        { data: data, metadata: metadata }
      end
    end
  end
end

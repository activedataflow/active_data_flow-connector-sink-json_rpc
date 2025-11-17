# frozen_string_literal: true

module ActiveDataFlow
  # Module for DataFlow orchestration
  # Include this module in your DataFlow classes
  module DataFlow
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Define configuration attributes for this DataFlow
      # Subclasses should override this to specify their configuration needs
      # @return [Hash] attribute definitions with types
      def configuration_attributes
        {}
      end
    end

    # Initialize with configuration
    # @param configuration [Hash] flow-specific settings
    def initialize(configuration = {})
      @configuration = Configuration.new(
        configuration,
        self.class.configuration_attributes
      )
      @logger = Logger.for(self.class.name)
    end

    # Abstract method to execute the flow
    # Must be implemented by including class
    def run
      raise NotImplementedError, "#{self.class}#run must be implemented"
    end

    protected

    attr_reader :configuration, :logger
  end
end

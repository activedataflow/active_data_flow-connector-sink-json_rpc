# frozen_string_literal: true

module ActiveDataFlow
  # Base class for all data sources
  class Source
    # Class method to define required configuration attributes
    # Subclasses should override this to specify their own needs
    # @return [Hash] attribute definitions with types
    def self.configuration_attributes
      {}
    end

    # Initialize with configuration hash
    # @param configuration [Hash] source-specific settings
    def initialize(configuration)
      @configuration = Configuration.new(
        configuration,
        self.class.configuration_attributes
      )
    end

    # Abstract method to iterate over messages
    # Must be implemented by subclasses
    # @yield [ActiveDataFlow::Message] each message from the source
    def each(&block)
      raise NotImplementedError, "#{self.class}#each must be implemented"
    end

    protected

    attr_reader :configuration
  end
end

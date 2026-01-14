# frozen_string_literal: true

module ActiveDataFlow
  # Shared configuration pattern for modules that need configurable settings.
  # Extend this module and define a Configuration class in your module.
  #
  # @example
  #   module MyModule
  #     extend ActiveDataFlow::ConfigurationBase
  #
  #     class Configuration
  #       attr_accessor :setting1, :setting2
  #
  #       def initialize
  #         @setting1 = 'default'
  #         @setting2 = 42
  #       end
  #     end
  #   end
  #
  #   MyModule.configure do |config|
  #     config.setting1 = 'custom'
  #   end
  #
  module ConfigurationBase
    def configuration
      @configuration ||= self::Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = self::Configuration.new
    end
  end
end

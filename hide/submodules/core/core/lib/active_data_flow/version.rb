# frozen_string_literal: true

module ActiveDataFlow
  VERSION = "0.1.1"

  # Version compatibility checking
  module Version
    class << self
      # Check if a plugin version is compatible
      # @param plugin_version [String] the plugin's required core version
      # @return [Boolean] true if compatible
      def compatible?(plugin_version)
        Gem::Dependency.new("", plugin_version).match?("", VERSION)
      end

      # Validate plugin compatibility, raise if incompatible
      # @param plugin_name [String] the plugin gem name
      # @param plugin_version [String] the plugin's required core version
      def validate!(plugin_name, plugin_version)
        unless compatible?(plugin_version)
          raise VersionError,
                "#{plugin_name} requires active_data_flow #{plugin_version}, " \
                "but #{VERSION} is loaded"
        end
      end
    end
  end
end

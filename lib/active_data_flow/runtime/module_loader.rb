# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    # Shared module loading functionality for runtime backends.
    # Handles loading models and controllers when Rails is available.
    module ModuleLoader
      # Loads models and controllers for a runtime backend.
      #
      # @param backend_name [String] The backend name (e.g., "heartbeat", "redcord")
      # @param models [Array<String>] Model filenames to load (without path)
      # @param controllers [Array<String>] Controller filenames to load (without path)
      def self.load_backend_files(backend_name, models:, controllers:)
        return unless defined?(Rails)

        base_path = File.expand_path("../../../../app", __FILE__)

        models.each do |model|
          require "#{base_path}/models/active_data_flow/runtime/#{backend_name}/#{model}"
        end

        controllers.each do |controller|
          require "#{base_path}/controllers/active_data_flow/runtime/#{backend_name}/#{controller}"
        end
      end

      # Standard models used by most runtime backends.
      STANDARD_MODELS = %w[data_flow data_flow_run].freeze

      # Loads standard models for a backend.
      #
      # @param backend_name [String] The backend name
      def self.load_standard_models(backend_name)
        return unless defined?(Rails)

        base_path = File.expand_path("../../../../app", __FILE__)

        STANDARD_MODELS.each do |model|
          path = "#{base_path}/models/active_data_flow/runtime/#{backend_name}/#{model}"
          require path if File.exist?("#{path}.rb")
        end
      end

      # Loads controllers for a backend.
      #
      # @param backend_name [String] The backend name
      # @param controller_names [Array<String>] Controller names to load
      def self.load_controllers(backend_name, controller_names)
        return unless defined?(Rails)

        base_path = File.expand_path("../../../../app", __FILE__)

        controller_names.each do |controller|
          path = "#{base_path}/controllers/active_data_flow/runtime/#{backend_name}/#{controller}"
          require path if File.exist?("#{path}.rb")
        end
      end
    end
  end
end

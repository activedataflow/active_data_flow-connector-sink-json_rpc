# frozen_string_literal: true

module ActiveDataFlow
  # Handles the startup and initialization of ActiveDataFlow engine
  #
  # This class is responsible for:
  # - Loading engine and host concerns
  # - Discovering and registering data flow classes
  # - Creating initial data flow runs for scheduling
  class DataFlowsFolder
    class << self
      include ActiveDataFlow::Result

      # Loads host concerns and registers data flows.
      #
      # @return [Dry::Monads::Result] Success with stats or Failure
      def load_host_concerns_and_flows
        data_flows_dir = Rails.root.join(ActiveDataFlow.configuration.data_flows_path)

        unless Dir.exist?(data_flows_dir)
          return Failure[:load_error, {
            message: "Data flows directory not found: #{data_flows_dir}",
            path: data_flows_dir.to_s
          }]
        end

        load_host_concerns(data_flows_dir)
        load_and_register_flows(data_flows_dir)
      end

      private

      def auto_load_enabled?
        unless ActiveDataFlow.configuration.auto_load_data_flows
          puts "[ActiveDataFlow] Auto-loading disabled"
          return false
        end
        true
      end

      def load_engine_concerns
        ActiveDataFlow::Concerns.load_engine_concerns(engine_root)
      end

      def load_host_concerns(data_flows_dir)
        concerns_path = data_flows_dir.join("concerns/**/*.rb")
        ActiveDataFlow::Concerns.load_host_concerns(concerns_path)
      end

      # Loads and registers all data flow files in the directory.
      #
      # @param data_flows_dir [Pathname] Path to data flows directory
      # @return [Dry::Monads::Result] Success with registration stats
      def load_and_register_flows(data_flows_dir)
        data_flows_path = data_flows_dir.join("**/*_flow.rb")
        data_flow_files = Dir[data_flows_path].sort

        if data_flow_files.empty?
          puts "[ActiveDataFlow] No data flow files found"
          return Success({ registered: 0, failed: 0, files: [] })
        end

        puts "[ActiveDataFlow] Found #{data_flow_files.size} data flow file(s)"

        results = data_flow_files.map { |file| register_flow_from_file(file) }

        successes = results.select(&:success?)
        failures = results.select(&:failure?)

        puts "[ActiveDataFlow] Registered #{successes.size} data flow(s)"
        puts "[ActiveDataFlow] Failed to load #{failures.size} file(s)" if failures.any?

        Success({
          registered: successes.size,
          failed: failures.size,
          failures: failures.map(&:failure)
        })
      end

      # Registers a single data flow from a file.
      #
      # @param file [String] Path to the data flow file
      # @return [Dry::Monads::Result] Success(flow_class) or Failure[:load_error, {...}]
      def register_flow_from_file(file)
        load file

        class_name = File.basename(file, ".rb").camelize

        unless Object.const_defined?(class_name)
          return Failure[:load_error, {
            message: "Class #{class_name} not defined after loading file",
            file: file,
            class_name: class_name
          }]
        end

        flow_class = Object.const_get(class_name)

        unless flow_class.respond_to?(:register)
          return Failure[:load_error, {
            message: "Class #{class_name} does not respond to :register",
            file: file,
            class_name: class_name
          }]
        end

        flow_class.register
        puts "[ActiveDataFlow] Registered: #{class_name}"
        Success(flow_class)
      rescue StandardError => e
        puts "[ActiveDataFlow] Failed to load #{file}: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        Failure[:load_error, {
          message: e.message,
          exception_class: e.class.name,
          file: file,
          backtrace: e.backtrace.first(5)
        }]
      end
    end
  end
end

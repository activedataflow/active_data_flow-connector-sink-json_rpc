# frozen_string_literal: true

module ActiveDataFlow
  # Registry for tracking data flow schedules and generating SolidQueue recurring.yml configuration.
  #
  # This class maintains a list of all scheduled data flows and provides methods to:
  # - Register flows with their schedules
  # - Generate recurring.yml configuration
  # - Sync schedules to the filesystem
  #
  # @example Registering a flow
  #   RecurringScheduleRegistry.register(UserSyncFlow, every: 5.minutes)
  #
  # @example Generating configuration
  #   yaml = RecurringScheduleRegistry.to_yaml
  #   File.write("config/recurring.yml", yaml)
  #
  class RecurringScheduleRegistry
    class << self
      # Registers a flow class with its schedule configuration.
      #
      # @param flow_class [Class] The data flow class
      # @param config [Hash] Schedule configuration
      # @return [Hash] The registered entry
      def register(flow_class, config)
        entries[flow_class.name] = {
          flow_class: flow_class,
          config: config,
          registered_at: Time.current
        }
      end

      # Unregisters a flow class.
      #
      # @param flow_class [Class] The data flow class to unregister
      def unregister(flow_class)
        entries.delete(flow_class.name)
      end

      # Clears all registered schedules.
      def clear!
        @entries = {}
      end

      # Returns all registered schedule entries.
      #
      # @return [Hash] Map of flow class names to their configurations
      def entries
        @entries ||= {}
      end

      # Returns all registered flow classes.
      #
      # @return [Array<Class>]
      def flow_classes
        entries.values.map { |e| e[:flow_class] }
      end

      # Generates the recurring.yml configuration hash.
      #
      # @return [Hash] Configuration suitable for SolidQueue recurring.yml
      def to_config
        config = {}

        entries.each do |class_name, entry|
          flow_class = entry[:flow_class]
          schedule_config = entry[:config]

          schedule_key = flow_class.respond_to?(:schedule_name) ? flow_class.schedule_name : class_name.underscore.tr("::", "_")

          config[schedule_key] = build_entry(flow_class, schedule_config)
        end

        config
      end

      # Generates YAML string for recurring.yml.
      #
      # @return [String] YAML configuration
      def to_yaml
        return empty_yaml_with_comment if entries.empty?

        yaml_content = to_config.to_yaml
        add_header_comment(yaml_content)
      end

      # Syncs the schedule configuration to config/recurring.yml.
      #
      # @param path [String, Pathname] Path to write the file (default: config/recurring.yml)
      # @param merge [Boolean] Whether to merge with existing entries (default: true)
      # @return [Hash] Result with :written, :entries, :path
      def sync_to_file(path: nil, merge: true)
        path ||= Rails.root.join("config", "recurring.yml")
        path = Pathname.new(path)

        existing = load_existing(path) if merge && path.exist?
        existing ||= {}

        # Generate new config
        new_config = to_config

        # Merge: existing entries not managed by us are preserved
        merged = existing.merge(new_config)

        # Write the file
        yaml_content = merged.empty? ? empty_yaml_with_comment : add_header_comment(merged.to_yaml)
        path.dirname.mkpath
        path.write(yaml_content)

        {
          written: true,
          entries: merged.keys,
          path: path.to_s,
          new_entries: new_config.keys,
          preserved_entries: (existing.keys - new_config.keys)
        }
      end

      # Loads existing recurring.yml if present.
      #
      # @param path [Pathname] Path to the file
      # @return [Hash, nil]
      def load_existing(path)
        return nil unless path.exist?

        content = path.read
        return nil if content.strip.empty?

        YAML.safe_load(content, permitted_classes: [Symbol]) || {}
      rescue Psych::SyntaxError => e
        Rails.logger.warn "[ActiveDataFlow] Failed to parse existing recurring.yml: #{e.message}"
        nil
      end

      # Scans database for flows with ActiveJob runtime and registers them.
      #
      # @return [Integer] Number of flows registered
      def register_from_database
        count = 0

        ActiveDataFlow::DataFlow.active.find_each do |flow|
          runtime = flow.parsed_runtime
          next unless runtime
          next unless runtime["class_name"] == "ActiveDataFlow::Runtime::ActiveJob"

          interval = runtime["interval"].to_i
          next unless interval > 0

          queue = runtime["queue"]&.to_sym || :active_data_flow
          priority = runtime["priority"]

          # Create a synthetic entry for database-configured flows
          register_database_flow(flow, interval: interval, queue: queue, priority: priority)
          count += 1
        end

        count
      end

      private

      def build_entry(flow_class, config)
        entry = {
          "class" => "ActiveDataFlow::DataFlowJob",
          "queue" => config[:queue]&.to_s || "active_data_flow"
        }

        # Add schedule
        if config[:every]
          entry["schedule"] = format_interval(config[:every])
        elsif config[:cron]
          entry["schedule"] = config[:cron]
        elsif config[:at]
          entry["schedule"] = config[:at]
        end

        # Add priority if specified
        entry["priority"] = config[:priority] if config[:priority]

        # Add args - the flow name to look up
        flow_name = derive_flow_name(flow_class)
        entry["args"] = [flow_name]

        entry
      end

      def derive_flow_name(flow_class)
        # Try to get the registered name from the flow class
        if flow_class.respond_to?(:schedule_name)
          flow_class.schedule_name.underscore
        else
          flow_class.name.underscore.gsub("_flow", "").tr("/", "_")
        end
      end

      def format_interval(duration)
        seconds = duration.is_a?(ActiveSupport::Duration) ? duration.to_i : duration.to_i

        case seconds
        when 0..59
          "every #{seconds} seconds"
        when 60..3599
          minutes = seconds / 60
          minutes == 1 ? "every minute" : "every #{minutes} minutes"
        when 3600..86399
          hours = seconds / 3600
          hours == 1 ? "every hour" : "every #{hours} hours"
        else
          days = seconds / 86400
          days == 1 ? "every day" : "every #{days} days"
        end
      end

      def register_database_flow(flow, interval:, queue:, priority:)
        # Create a placeholder class entry for database-configured flows
        entries["DatabaseFlow::#{flow.name}"] = {
          flow_class: nil,
          flow_name: flow.name,
          config: {
            every: interval,
            queue: queue,
            priority: priority
          },
          registered_at: Time.current,
          source: :database
        }
      end

      def empty_yaml_with_comment
        <<~YAML
          # ActiveDataFlow Recurring Schedules
          # Generated by: rails active_data_flow:schedules:sync
          #
          # This file configures SolidQueue recurring jobs for data flows.
          # See: https://github.com/rails/solid_queue#recurring-tasks
          #
          # Example:
          #   user_sync_flow:
          #     class: ActiveDataFlow::DataFlowJob
          #     queue: active_data_flow
          #     schedule: every 5 minutes
          #     args:
          #       - user_sync
          #
          # No scheduled flows registered yet.
        YAML
      end

      def add_header_comment(yaml_content)
        header = <<~HEADER
          # ActiveDataFlow Recurring Schedules
          # Generated by: rails active_data_flow:schedules:sync
          # Last updated: #{Time.current.iso8601}
          #
          # This file configures SolidQueue recurring jobs for data flows.
          # Manual entries will be preserved on regeneration.
          #
        HEADER

        header + yaml_content.sub(/\A---\n/, "")
      end
    end
  end
end

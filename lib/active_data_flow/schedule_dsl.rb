# frozen_string_literal: true

module ActiveDataFlow
  # DSL for declaring schedules on data flow classes.
  #
  # This module provides a declarative way to define when a data flow should run,
  # which integrates with SolidQueue's recurring jobs feature.
  #
  # @example Every interval
  #   class UserSyncFlow < ActiveDataFlow::DataFlow
  #     include ActiveDataFlow::ScheduleDSL
  #
  #     schedule every: 5.minutes
  #     schedule every: 1.hour, queue: :low_priority
  #   end
  #
  # @example Cron expression
  #   class DailyReportFlow < ActiveDataFlow::DataFlow
  #     include ActiveDataFlow::ScheduleDSL
  #
  #     schedule cron: "0 2 * * *"  # Daily at 2am
  #     schedule cron: "*/15 * * * *", queue: :reports  # Every 15 minutes
  #   end
  #
  # @example At specific times
  #   class WeeklyDigestFlow < ActiveDataFlow::DataFlow
  #     include ActiveDataFlow::ScheduleDSL
  #
  #     schedule at: "monday 9am"
  #   end
  #
  module ScheduleDSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Declares a schedule for this data flow.
      #
      # @param every [ActiveSupport::Duration, Integer, nil] Interval between runs
      # @param cron [String, nil] Cron expression for scheduling
      # @param at [String, nil] Human-readable time expression (e.g., "monday 9am")
      # @param queue [Symbol] Queue to use for the job (default: :active_data_flow)
      # @param priority [Integer, nil] Job priority (lower = higher priority)
      # @param args [Hash] Additional arguments to pass to the job
      # @return [Hash] The schedule configuration
      def schedule(every: nil, cron: nil, at: nil, queue: :active_data_flow, priority: nil, **args)
        @_schedule_config = {
          every: every,
          cron: cron,
          at: at,
          queue: queue,
          priority: priority,
          args: args
        }.compact

        # Register with the global schedule registry
        RecurringScheduleRegistry.register(self, @_schedule_config)

        @_schedule_config
      end

      # Returns the schedule configuration for this flow.
      #
      # @return [Hash, nil] The schedule configuration or nil if not scheduled
      def schedule_config
        @_schedule_config
      end

      # Returns true if this flow has a schedule defined.
      #
      # @return [Boolean]
      def scheduled?
        !@_schedule_config.nil?
      end

      # Returns the flow name for use in recurring.yml.
      # Defaults to underscored class name.
      #
      # @return [String]
      def schedule_name
        @_schedule_name || name.underscore.tr("/", "_")
      end

      # Sets a custom schedule name.
      #
      # @param name [String] Custom name for the schedule
      def schedule_as(name)
        @_schedule_name = name.to_s
      end
    end
  end
end

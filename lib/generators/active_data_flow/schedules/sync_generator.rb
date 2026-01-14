# frozen_string_literal: true

require "rails/generators"

module ActiveDataFlow
  module Schedules
    module Generators
      class SyncGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc "Syncs ActiveDataFlow schedules to config/recurring.yml for SolidQueue"

        class_option :include_database,
                     type: :boolean,
                     default: true,
                     desc: "Include flows configured via database with ActiveJob runtime"

        class_option :output,
                     type: :string,
                     default: "config/recurring.yml",
                     desc: "Output path for recurring.yml"

        def check_solid_queue
          unless solid_queue_available?
            say "Note: SolidQueue not detected. The generated recurring.yml will only work with SolidQueue.", :yellow
            say ""
          end
        end

        def load_flows
          say "Loading data flow classes..."

          # Trigger flow loading if not already done
          if defined?(ActiveDataFlow::DataFlowsFolder)
            ActiveDataFlow::DataFlowsFolder.load_host_concerns_and_flows
          end

          flow_count = ActiveDataFlow::RecurringScheduleRegistry.entries.size
          say "  Found #{flow_count} flow(s) with DSL schedules"
        end

        def register_database_flows
          return unless options[:include_database]

          say "Scanning database for flows with ActiveJob runtime..."

          begin
            count = ActiveDataFlow::RecurringScheduleRegistry.register_from_database
            say "  Found #{count} flow(s) configured in database"
          rescue StandardError => e
            say "  Could not scan database: #{e.message}", :yellow
          end
        end

        def generate_recurring_yml
          output_path = Rails.root.join(options[:output])

          say "Generating #{output_path}..."

          result = ActiveDataFlow::RecurringScheduleRegistry.sync_to_file(
            path: output_path,
            merge: true
          )

          if result[:written]
            say "  Created/updated: #{result[:path]}", :green
            say "  Entries: #{result[:entries].join(', ')}" if result[:entries].any?

            if result[:preserved_entries]&.any?
              say "  Preserved existing: #{result[:preserved_entries].join(', ')}", :cyan
            end
          else
            say "  Failed to write file", :red
          end
        end

        def show_instructions
          say ""
          say "Schedule sync complete!", :green
          say ""
          say "Next steps:", :yellow
          say "  1. Review config/recurring.yml"
          say "  2. Ensure SolidQueue is configured:"
          say "       config.active_job.queue_adapter = :solid_queue"
          say ""
          say "  3. Start the scheduler:"
          say "       bin/jobs"
          say ""
          say "  4. To add schedules via DSL, include ScheduleDSL in your flow:"
          say ""
          say "       class MyFlow < ActiveDataFlow::DataFlow"
          say "         include ActiveDataFlow::ScheduleDSL"
          say ""
          say "         schedule every: 5.minutes"
          say "         # or"
          say "         schedule cron: '0 2 * * *'  # Daily at 2am"
          say "       end"
          say ""
        end

        private

        def solid_queue_available?
          defined?(SolidQueue)
        rescue NameError
          false
        end
      end
    end
  end
end

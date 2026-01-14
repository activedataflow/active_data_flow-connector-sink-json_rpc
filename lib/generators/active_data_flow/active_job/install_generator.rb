# frozen_string_literal: true

require "rails/generators"

module ActiveDataFlow
  module ActiveJob
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc "Installs ActiveDataFlow with ActiveJob runtime support"

        def check_active_job
          unless defined?(::ActiveJob)
            say "ActiveJob is required for this generator.", :red
            raise Thor::Error, "Please ensure ActiveJob is available in your application."
          end
        end

        def copy_initializer
          template "initializer.rb",
                   "config/initializers/active_data_flow_active_job.rb"
        end

        def copy_application_job_if_missing
          app_job_path = Rails.root.join("app/jobs/application_job.rb")
          unless File.exist?(app_job_path)
            template "application_job.rb", "app/jobs/application_job.rb"
          end
        end

        def show_instructions
          say ""
          say "ActiveDataFlow ActiveJob runtime installed!", :green
          say ""
          say "Configuration added to config/initializers/active_data_flow_active_job.rb"
          say ""
          say "Next steps:", :yellow
          say "  1. Configure your queue adapter in config/application.rb"
          say "     For SolidQueue (Rails 8+ default):"
          say "       config.active_job.queue_adapter = :solid_queue"
          say ""
          say "  2. For SolidQueue, install it:"
          say "       bin/rails solid_queue:install"
          say ""
          say "  3. Start processing jobs:"
          say "       bin/jobs"
          say ""
          say "  4. Create a flow with ActiveJob runtime:"
          say "       runtime = ActiveDataFlow::Runtime::ActiveJob.new("
          say "         queue: :active_data_flow,"
          say "         interval: 5.minutes"
          say "       )"
          say ""
        end
      end
    end
  end
end

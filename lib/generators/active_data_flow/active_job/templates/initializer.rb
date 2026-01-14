# frozen_string_literal: true

# ActiveDataFlow ActiveJob Runtime Configuration
#
# This configures ActiveDataFlow to use ActiveJob for flow execution,
# integrating with Rails' native job infrastructure (SolidQueue, Sidekiq, etc.)

ActiveDataFlow.configure do |config|
  # Use ActiveJob runtime adapter
  config.runtime_adapter = :active_job
end

# Optional: Configure retry behavior for DataFlowJob
# Rails.application.config.after_initialize do
#   ActiveDataFlow::DataFlowJob.retry_on(
#     YourCustomError,
#     wait: 10.seconds,
#     attempts: 3
#   )
# end

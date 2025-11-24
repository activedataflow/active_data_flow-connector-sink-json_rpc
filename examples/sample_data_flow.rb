# frozen_string_literal: true

# Example data flow class that would be placed in app/data_flows/
# This file demonstrates how to define a data flow that gets automatically
# registered when the Rails application starts

class UserSyncFlow
  # Register the data flow on application startup
  def self.register
    # Define source - where data comes from
    source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
      model_class: User,
      scope_name: :active  # Assumes User.active scope exists
    )

    # Define sink - where data goes
    sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
      model_class: UserBackup,
      batch_size: 100
    )

    # Define runtime (optional)
    runtime = ActiveDataFlow::Runtime::Base.new(
      interval: 3600,   # Run every hour
      batch_size: 100,  # Source iteration batch size
      enabled: true     # Whether the data flow is enabled
    )

    # Register the data flow
    ActiveDataFlow::DataFlow.find_or_create(
      name: "user_sync",
      source: source,
      sink: sink,
      runtime: runtime
    )
  end
end

# Note: The .register method is automatically called by config/initializers/data_flows.rb
# after ActiveRecord is available. You don't need to call it manually.

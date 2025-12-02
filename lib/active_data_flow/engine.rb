# frozen_string_literal: true

require "rails"

module ActiveDataFlow
  class Engine < ::Rails::Engine
    puts "[ActiveDataFlow] Engine class loaded"
    
    isolate_namespace ActiveDataFlow

    config.autoload_paths << root.join("app/data_flows/concerns")
    config.eager_load_paths << root.join("app/data_flows/concerns")

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Load storage backend before other initializers
    initializer "active_data_flow.load_storage_backend", before: :load_config_initializers do
      ActiveDataFlow::StorageBackendLoader.setup_autoload_paths(self)
    end

    initializer "active_data_flow.log_startup" do
      puts "[ActiveDataFlow] Initializer running"
      ActiveDataFlow::StorageBackendLoader.log_configuration
    end

    initializer "active_data_flow.assets" do |app|
      app.config.assets.paths << root.join("app/assets")
      app.config.assets.precompile += %w[active_data_flow_manifest.js]
    end

    # Register data flows after initialization
    config.after_initialize do
      puts "[ActiveDataFlow] after_initialize callback"
      
      # Define the registration logic using the refactored Startup scheduler
      registration_proc = proc do
        ActiveDataFlow::Scheduler.startup(root)
      end
      
      # Run immediately in after_initialize
      registration_proc.call
      
      # Also set up to_prepare for development reloading
      Rails.application.config.to_prepare(&registration_proc)
    end
  end
end

puts "[ActiveDataFlow] Engine file loaded"

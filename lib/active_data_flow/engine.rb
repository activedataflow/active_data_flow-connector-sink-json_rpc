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

    initializer "active_data_flow.log_startup" do
      puts "[ActiveDataFlow] Initializer running"
    end

    initializer "active_data_flow.assets" do |app|
      app.config.assets.paths << root.join("app/assets")
      app.config.assets.precompile += %w[active_data_flow_manifest.js]
    end

    # Register data flows after initialization
    config.after_initialize do
      puts "[ActiveDataFlow] after_initialize callback"
      
      # Define the registration logic
      registration_proc = proc do
        puts "[ActiveDataFlow] Loading data flows..."
        
        unless ActiveDataFlow.configuration.auto_load_data_flows
          puts "[ActiveDataFlow] Auto-loading disabled"
          next
        end
        
        # Load engine concerns
        ActiveDataFlow::Concerns.load_engine_concerns(root)
        
        # Load host concerns and data flows
        data_flows_dir = Rails.root.join(ActiveDataFlow.configuration.data_flows_path)
        
        if Dir.exist?(data_flows_dir)
          # Load host concerns
          concerns_path = data_flows_dir.join("concerns/**/*.rb")
          ActiveDataFlow::Concerns.load_host_concerns(concerns_path)

          # Load and register data flows
          data_flows_path = data_flows_dir.join("**/*_flow.rb")
          data_flow_files = Dir[data_flows_path].sort
          
          if data_flow_files.any?
            puts "[ActiveDataFlow] Found #{data_flow_files.size} data flow file(s)"
            
            registered_count = 0
            data_flow_files.each do |file|
              begin
                load file
                
                # Extract class name from file path
                class_name = File.basename(file, ".rb").camelize
                
                # Try to register the data flow if it has a register method
                if Object.const_defined?(class_name)
                  flow_class = Object.const_get(class_name)
                  
                  if flow_class.respond_to?(:register)
                    flow_class.register
                    registered_count += 1
                    puts "[ActiveDataFlow] Registered: #{class_name}"
                  end
                end
                
              rescue StandardError => e
                puts "[ActiveDataFlow] Failed to load #{file}: #{e.message}"
                puts e.backtrace.first(5).join("\n")
              end
            end
            
            puts "[ActiveDataFlow] Registered #{registered_count} data flow(s)"
          else
            puts "[ActiveDataFlow] No data flow files found"
          end
        else
          puts "[ActiveDataFlow] Data flows directory not found: #{data_flows_dir}"
        end
        
        puts "[ActiveDataFlow] Initialization complete"
      end
      
      # Run immediately in after_initialize
      begin
        registration_proc.call
      rescue => e
        puts "[ActiveDataFlow] Error during initialization: #{e.message}"
        puts e.backtrace.first(10).join("\n")
      end
      
      # Also set up to_prepare for development reloading
      Rails.application.config.to_prepare(&registration_proc)
    end
  end
end

puts "[ActiveDataFlow] Engine file loaded"

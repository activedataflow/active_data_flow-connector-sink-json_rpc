module ActiveDataFlow
    # Handles the startup and initialization of ActiveDataFlow engine
    # 
    # This class is responsible for:
    # - Loading engine and host concerns
    # - Discovering and registering data flow classes
    # - Creating initial data flow runs for scheduling
    class DataFlowsFolder
      class << self

        def load_host_concerns_and_flows
          data_flows_dir = Rails.root.join(ActiveDataFlow.configuration.data_flows_path)
          
          unless Dir.exist?(data_flows_dir)
            puts "[ActiveDataFlow] Data flows directory not found: #{data_flows_dir}"
            return
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

        def load_and_register_flows(data_flows_dir)
          data_flows_path = data_flows_dir.join("**/*_flow.rb")
          data_flow_files = Dir[data_flows_path].sort
          
          return puts "[ActiveDataFlow] No data flow files found" if data_flow_files.empty?
          
          puts "[ActiveDataFlow] Found #{data_flow_files.size} data flow file(s)"
          
          registered_count = 0
          data_flow_files.each do |file|
            registered_count += 1 if register_flow_from_file(file)
          end
          
          puts "[ActiveDataFlow] Registered #{registered_count} data flow(s)"
        end

        def register_flow_from_file(file)
          load file
          
          class_name = File.basename(file, ".rb").camelize
          
          return false unless Object.const_defined?(class_name)
          
          flow_class = Object.const_get(class_name)
          
          if flow_class.respond_to?(:register)
            flow_class.register
            puts "[ActiveDataFlow] Registered: #{class_name}"
            true
          else
            false
          end
        rescue StandardError => e
          puts "[ActiveDataFlow] Failed to load #{file}: #{e.message}"
          puts e.backtrace.first(5).join("\n")
          false
        end
      end
    end
end
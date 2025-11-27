# frozen_string_literal: true

module ActiveDataFlow
  module Scheduler
    # Handles the startup and initialization of ActiveDataFlow engine
    # 
    # This class is responsible for:
    # - Loading engine and host concerns
    # - Discovering and registering data flow classes
    # - Creating initial data flow runs for scheduling
    class Startup
      attr_reader :engine_root

      def initialize(engine_root)
        @engine_root = engine_root
      end

      # Main entry point for startup initialization
      # @param engine_root [Pathname] The root path of the ActiveDataFlow engine
      def self.call(engine_root)
        new(engine_root).call
      end

      def call
        puts "[ActiveDataFlow] Loading data flows..."
        
        return unless auto_load_enabled?
        
        load_engine_concerns
        load_host_concerns_and_flows
        change_pending_to_canceled
        create_initial_runs
        
        puts "[ActiveDataFlow] Initialization complete"
      rescue StandardError => e
        puts "[ActiveDataFlow] Error during initialization: #{e.message}"
        puts e.backtrace.first(10).join("\n")
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

      def load_host_concerns_and_flows
        data_flows_dir = Rails.root.join(ActiveDataFlow.configuration.data_flows_path)
        
        unless Dir.exist?(data_flows_dir)
          puts "[ActiveDataFlow] Data flows directory not found: #{data_flows_dir}"
          return
        end

        load_host_concerns(data_flows_dir)
        load_and_register_flows(data_flows_dir)
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

      def create_initial_runs
        run_count = 0
        
        DataFlow.all.each do |data_flow|
          next if has_future_pending_run?(data_flow)
          
          create_initial_run_for_flow(data_flow)
          run_count += 1
        end
        
        puts "[ActiveDataFlow] Created #{run_count} data flow_run(s)"
      end

      def has_future_pending_run?(data_flow)
        data_flow.data_flow_runs.pending.where('run_after > ?', Time.current).exists?
      end

      def create_initial_run_for_flow(data_flow)
        interval = data_flow.interval_seconds
        next_run = Time.current + interval
        
        data_flow.data_flow_runs.create!(
          status: 'pending',
          run_after: next_run
        )
      end

      # Cancel all pending runs that are overdue or stale from previous sessions
      def change_pending_to_canceled
        # Find pending runs that are significantly overdue (more than 1 hour past their run_after time)
        overdue_runs = DataFlowRun.pending.where('run_after < ?', 1.hour.ago)
        canceled_count = overdue_runs.update_all(status: 'cancelled')
        
        if canceled_count > 0
          puts "[ActiveDataFlow] Canceled #{canceled_count} overdue pending run(s)"
        end
      end
    end
  end
end
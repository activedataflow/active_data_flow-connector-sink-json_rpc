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
        ActiveDataFlow::DataFlowsFolder.load_host_concerns_and_flows
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
        DataFlowRun.create_pending_for_data_flow(data_flow)
      end

      # Cancel all pending runs that are overdue or stale from previous sessions
      def change_pending_to_canceled
        # Find pending runs that are significantly overdue (more than 1 hour past their run_after time)
        overdue_runs = DataFlowRun.overdue
        canceled_count = overdue_runs.update_all(status: 'cancelled')
        
        if canceled_count > 0
          puts "[ActiveDataFlow] Canceled #{canceled_count} overdue pending run(s)"
        end
      end
    end
  end
end
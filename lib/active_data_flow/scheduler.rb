# frozen_string_literal: true

module ActiveDataFlow
  module Scheduler
    autoload :Startup, 'active_data_flow/scheduler/startup'
 
    def self.startup(engine_root)
      Startup.call(engine_root)
    end

  end
end
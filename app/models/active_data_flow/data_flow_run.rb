# frozen_string_literal: true

# Backward compatibility: Alias to the backend-specific implementation
# This file maintains compatibility with existing code that references ActiveDataFlow::DataFlowRun

module ActiveDataFlow
  # Dynamically load the appropriate backend model based on configuration
  def self.DataFlowRun
    case configuration.storage_backend
    when :active_record
      ActiveDataFlow::ActiveRecord::DataFlowRun
    when :redcord_redis, :redcord_redis_emulator
      ActiveDataFlow::Redcord::DataFlowRun
    else
      # Default to ActiveRecord
      ActiveDataFlow::ActiveRecord::DataFlowRun
    end
  end
end

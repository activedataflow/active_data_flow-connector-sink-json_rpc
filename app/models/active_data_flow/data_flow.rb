# frozen_string_literal: true

# Backward compatibility: Alias to the backend-specific implementation
# This file maintains compatibility with existing code that references ActiveDataFlow::DataFlow

module ActiveDataFlow
  # Dynamically load the appropriate backend model based on configuration
  def self.DataFlow
    case configuration.storage_backend
    when :active_record
      ActiveDataFlow::ActiveRecord::DataFlow
    when :redcord_redis, :redcord_redis_emulator
      ActiveDataFlow::Redcord::DataFlow
    else
      # Default to ActiveRecord
      ActiveDataFlow::ActiveRecord::DataFlow
    end
  end
end

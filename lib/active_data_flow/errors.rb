# frozen_string_literal: true

module ActiveDataFlow
  # Base error class for ActiveDataFlow
  class Error < StandardError; end

  # Raised when storage backend configuration is invalid
  class ConfigurationError < Error; end

  # Raised when Redis connection fails
  class ConnectionError < Error; end

  # Raised when required gems are not installed
  class DependencyError < Error; end
end

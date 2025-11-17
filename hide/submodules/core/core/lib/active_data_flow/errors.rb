# frozen_string_literal: true

module ActiveDataFlow
  # Base error class for all ActiveDataFlow errors
  class Error < StandardError; end

  # Configuration-related errors
  class ConfigurationError < Error; end

  # Source-related errors
  class SourceError < Error; end

  # Sink-related errors
  class SinkError < Error; end

  # Runtime-related errors
  class RuntimeError < Error; end

  # Version compatibility errors
  class VersionError < Error; end
end

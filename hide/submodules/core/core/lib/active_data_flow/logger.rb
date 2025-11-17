# frozen_string_literal: true

module ActiveDataFlow
  # Logger module for structured logging
  module Logger
    class << self
      # Get a logger for a specific component
      # @param name [String] the component name
      # @return [LoggerInstance] a logger instance
      def for(name)
        LoggerInstance.new(name)
      end

      # Configure the logging backend
      # @param backend [Object] the logging backend (e.g., Rails.logger)
      def backend=(backend)
        @backend = backend
      end

      # Get the current logging backend
      # @return [Object] the logging backend
      def backend
        @backend ||= default_backend
      end

      private

      def default_backend
        if defined?(Rails)
          Rails.logger
        else
          require "logger"
          ::Logger.new($stdout)
        end
      end
    end

    # Logger instance for a specific component
    class LoggerInstance
      def initialize(name)
        @name = name
      end

      def debug(message = nil, **context, &block)
        log(:debug, message, context, &block)
      end

      def info(message = nil, **context, &block)
        log(:info, message, context, &block)
      end

      def warn(message = nil, **context, &block)
        log(:warn, message, context, &block)
      end

      def error(message = nil, **context, &block)
        log(:error, message, context, &block)
      end

      private

      def log(level, message, context, &block)
        message = block.call if block_given?
        formatted = format_message(message, context)
        Logger.backend.send(level, formatted)
      end

      def format_message(message, context)
        parts = ["[#{@name}]", message]
        unless context.empty?
          parts << context.map { |k, v| "#{k}=#{v}" }.join(" ")
        end
        parts.join(" ")
      end
    end
  end
end

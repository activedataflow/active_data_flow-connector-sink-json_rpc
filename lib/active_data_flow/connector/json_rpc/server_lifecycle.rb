# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module JsonRpc
      # Manages JSON-RPC server lifecycle with proper synchronization.
      # Extracted from JsonRpcSource to provide reusable server management.
      class ServerLifecycle
        attr_reader :host, :port, :handler

        # Initialize server lifecycle manager.
        #
        # @param host [String] The host to bind to
        # @param port [Integer] The port to bind to
        # @param handler [Object] The Jimson handler object
        def initialize(host:, port:, handler:)
          @host = host
          @port = port
          @handler = handler
          @server = nil
          @server_thread = nil
          @mutex = Mutex.new
          @started = ConditionVariable.new
          @running = false
        end

        # Start the JSON-RPC server.
        # Uses a ConditionVariable for proper synchronization instead of sleep.
        #
        # @param timeout [Float] Maximum seconds to wait for server start
        # @return [Boolean] true if server started successfully
        def start(timeout: 2.0)
          @mutex.synchronize do
            return true if @running

            @server = Jimson::Server.new(@handler, host: @host, port: @port)

            @server_thread = Thread.new do
              begin
                @mutex.synchronize do
                  @running = true
                  @started.signal
                end
                @server.start
              rescue => e
                log_error("JSON-RPC Server error: #{e.message}")
                @mutex.synchronize do
                  @running = false
                end
              end
            end

            # Wait for server to signal it's started
            @started.wait(@mutex, timeout)
            @running
          end
        end

        # Stop the JSON-RPC server.
        #
        # @return [void]
        def stop
          @mutex.synchronize do
            return unless @running

            @server&.stop
            @server_thread&.kill
            @server_thread&.join(1) # Wait up to 1 second for thread to finish
            @running = false
            @server = nil
            @server_thread = nil
          end
        end

        # Check if server is running.
        #
        # @return [Boolean]
        def running?
          @mutex.synchronize { @running }
        end

        # Get the server URL.
        #
        # @return [String]
        def url
          "http://#{host}:#{port}"
        end

        private

        def log_error(message)
          if defined?(Rails)
            Rails.logger.error(message)
          else
            $stderr.puts message
          end
        end
      end
    end
  end
end

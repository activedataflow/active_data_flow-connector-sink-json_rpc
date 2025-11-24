# frozen_string_literal: true

require 'ostruct'

module ActiveDataFlow
  module ActiveRecord2ActiveRecord
    extend ActiveSupport::Concern

    included do
      class_attribute :_source_config, :_sink_config, :_runtime_config
    end

    class_methods do
      def source(scope)
        self._source_config = { scope: scope }
      end

      def sink(model_class)
        self._sink_config = { model_class: model_class }
      end

      def runtime(type, **options)
        interval = options[:interval] || 3600
        batch_size = options[:batch_size] || 100
        enabled = options.fetch(:enabled, true)
        self._runtime_config = { type: type, interval: interval, batch_size: batch_size, enabled: enabled }
      end

      def register(name: nil)
        flow_name = name || self.name.underscore
        source_config = _source_config
        sink_config = _sink_config
        runtime_config = _runtime_config

        raise "source not configured for #{self.name}" unless source_config
        raise "sink not configured for #{self.name}" unless sink_config

        batch_size = runtime_config&.dig(:batch_size) || 100

        source_obj = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
          scope: source_config[:scope],
          batch_size: batch_size
        )

        sink_obj = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
          model_class: sink_config[:model_class]
        )

        runtime_obj = if runtime_config
          case runtime_config[:type]
          when :heartbeat
            ActiveDataFlow::Runtime::Base.new(interval: runtime_config[:interval])
          else
            ActiveDataFlow::Runtime::Base.new(interval: runtime_config[:interval])
          end
        else
          nil
        end

        data_flow = ActiveDataFlow::DataFlow.find_or_create(
          name: flow_name,
          source: source_obj,
          sink: sink_obj,
          runtime: runtime_obj
        )
        
        # Update status based on enabled flag
        if runtime_config && runtime_config[:enabled] == false
          data_flow.update(status: 'inactive')
        end
        
        data_flow
      end
    end

    def initialize
      # Reconstruct source and sink from class config
      source_config = self.class._source_config
      sink_config = self.class._sink_config
      runtime_config = self.class._runtime_config
      
      batch_size = runtime_config&.dig(:batch_size) || 100
      
      @source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
        scope: source_config[:scope],
        batch_size: batch_size
      )
      
      @sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
        model_class: sink_config[:model_class]
      )
      
      # Create a simple object to hold source and sink
      @flow = OpenStruct.new(source: @source, sink: @sink)
    end
  end
end

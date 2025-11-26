# frozen_string_literal: true

module ActiveDataFlow
  module ActiveRecord2ActiveRecord
    extend ActiveSupport::Concern

    included do
      class_attribute :_source_config, :_sink_config, :_runtime_config
    end

    class_methods do
      def source(model_or_scope, batch_size: 100)
        self._source_config = { model_or_scope: model_or_scope, batch_size: batch_size }
      end

      def sink(model_class, batch_size: 100)
        self._sink_config = { model_class: model_class, batch_size: batch_size }
      end

      def runtime(type, interval: 3600, batch_size: 100, enabled: true)
        self._runtime_config = { type: type, interval: interval, batch_size: batch_size, enabled: enabled }
      end

      def register(name: nil)
        flow_name = name || self.name.underscore
        source_config = _source_config
        sink_config = _sink_config
        runtime_config = _runtime_config

        raise "source not configured for #{self.name}" unless source_config
        raise "sink not configured for #{self.name}" unless sink_config

        source_obj = if source_config[:model_or_scope].is_a?(ActiveRecord::Relation)
          ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
            model_class: source_config[:model_or_scope].klass,
            scope: ->(_relation) { source_config[:model_or_scope] },
            batch_size: source_config[:batch_size]
          )
        else
          ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
            model_class: source_config[:model_or_scope],
            batch_size: source_config[:batch_size]
          )
        end

        sink_obj = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
          model_class: sink_config[:model_class],
          batch_size: sink_config[:batch_size]
        )

        runtime_obj = if runtime_config
          case runtime_config[:type]
          when :heartbeat
            ActiveDataFlow::Runtime::Base.new(
              interval: runtime_config[:interval],
              batch_size: runtime_config[:batch_size],
              enabled: runtime_config[:enabled]
            )
          else
            ActiveDataFlow::Runtime::Base.new(
              interval: runtime_config[:interval],
              batch_size: runtime_config[:batch_size],
              enabled: runtime_config[:enabled]
            )
          end
        else
          nil
        end

        ActiveDataFlow::DataFlow.find_or_create(
          name: flow_name,
          source: source_obj,
          sink: sink_obj,
          runtime: runtime_obj
        )
      end
    end

    def initialize
      @flow = self.class.register
    end

    # Check if this flow has any runs due to execute
    def due_to_run?
      @flow.next_due_run.present?
    end

    # Execute the flow if it's due to run
    def run_if_due
      return false unless due_to_run?
      
      run_record = @flow.next_due_run
      run_record.start!
      
      begin
        run
        run_record.complete!
        true
      rescue StandardError => e
        run_record.fail!(e)
        raise
      end
    end
  end
end

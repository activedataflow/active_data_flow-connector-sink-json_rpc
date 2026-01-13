# frozen_string_literal: true

require "active_record"
require "active_data_flow/connector/sink/base"

module ActiveDataFlow
  module Connector
    module Sink
      class ActiveRecordSink < ::ActiveDataFlow::Connector::Sink::Base
        attr_reader :model_class, :batch_size

        def initialize(model_class:, batch_size: 100)
          @model_class = model_class
          @batch_size = batch_size

          # Store serializable representation
          super(
            model_class: model_class.name,
            batch_size: batch_size
          )
        end

        def write(record)
          model_class.create!(record)
        end

        def write_batch(records)
          model_class.insert_all!(records) if records.any?
        end

        def close
          # Release any resources if needed
        end

        # Override deserialization to reconstruct model class
        def self.from_json(data)
          model_class = Object.const_get(data["model_class"])
          new(model_class: model_class, batch_size: data["batch_size"])
        end
      end
    end
  end
end

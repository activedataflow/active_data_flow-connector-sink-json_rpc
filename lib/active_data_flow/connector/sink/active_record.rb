# frozen_string_literal: true

require "active_record"
require "active_data_flow/connector/sink/base"

module ActiveDataFlow
  module Connector
    module Sink
      class ActiveRecordSink < ::ActiveDataFlow::Connector::Sink::Base
        include ActiveDataFlow::Result

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

        # Write a single record to the database
        #
        # @param record [Hash] The record attributes
        # @return [Dry::Monads::Result] Success(record) or Failure[:db_error, {...}]
        def write(record)
          result = model_class.create!(record)
          Success(result)
        rescue StandardError => e
          Failure[:db_error, {
            message: e.message,
            exception_class: e.class.name,
            model_class: model_class.name,
            record_count: 1
          }]
        end

        # Write multiple records to the database
        #
        # @param records [Array<Hash>] Array of record attributes
        # @return [Dry::Monads::Result] Success(result) or Failure[:db_error, {...}]
        def write_batch(records)
          return Success(nil) unless records.any?

          result = model_class.insert_all!(records)
          Success(result)
        rescue StandardError => e
          Failure[:db_error, {
            message: e.message,
            exception_class: e.class.name,
            model_class: model_class.name,
            record_count: records.size
          }]
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

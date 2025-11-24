# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Source
      class ActiveRecordSource < ::ActiveDataFlow::Connector::Source::Base
        attr_reader :model_class, :scope_name, :scope_params, :batch_size

        def initialize(scope:, batch_size: 100, scope_params: [])
          raise ArgumentError, "scope is required" if scope.nil?
          
          # Validate that this is a named scope, not an ad-hoc where clause
          unless scope.respond_to?(:name) && scope.name.present?
            raise ArgumentError, "source must be a named scope (e.g., Product.active), not an ad-hoc query like Product.where(...)"
          end
          
          # Store the scope directly
          @scope = scope
          
          # Extract model for serialization
          @model_class = scope.model
          @scope_name = scope.name
          @scope_params = scope_params
          
          @batch_size = batch_size
          
          # Store serializable representation
          super(
            model_class: @model_class.name,
            scope_name: @scope_name,
            scope_params: @scope_params,
            batch_size: @batch_size
          )
        end

        def each(&block)
          scope.find_each(batch_size: batch_size, &block)
        end

        def close
          # Release any resources if needed
        end
        
        private
        
        attr_reader :scope
        
        def build_scope
          model_class.public_send(scope_name, *scope_params)
        end
        
        # Override deserialization to reconstruct scope
        def self.from_json(data)
          model_class = Object.const_get(data["model_class"])
          scope = model_class.public_send(data["scope_name"])
          
          new(
            scope: scope,
            scope_params: data["scope_params"],
            batch_size: data["batch_size"]
          )
        end
      end
    end
  end
end

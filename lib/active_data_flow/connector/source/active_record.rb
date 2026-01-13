# frozen_string_literal: true

require "active_record"
require "active_data_flow/connector/source/base"

module ActiveDataFlow
  module Connector
    module Source
      class ActiveRecordSource < ::ActiveDataFlow::Connector::Source::Base
        attr_reader :scope_params

        def initialize(scope:, scope_params: [])
          raise ArgumentError, "scope is required" if scope.nil?

          # Validate that this is a named scope, not an ad-hoc where clause
          unless scope.respond_to?(:name) && scope.name.present?
            raise ArgumentError, "source must be a named scope (e.g., Product.active), not an ad-hoc query like Product.where(...)"
          end

          # Store the scope and scope_params directly
          @scope = scope
          @scope_params = scope_params

          # Derive scope_name from the calling context
          # This will be overridden by subclasses that need specific scope names
          @scope_name = derive_scope_name

          # Store serializable representation
          super(
            model_class: model_class.name,
            scope_name: @scope_name,
            scope_params: @scope_params
          )
        end

        def model_class
          @scope.model
        end

        attr_reader :scope_name

        def each(batch_size:, start_id: nil, &block)
          scope_with_cursor = if start_id
            scope.where("#{model_class.table_name}.id > ?", start_id)
          else
            scope
          end

          scope_with_cursor.find_each(batch_size: batch_size, &block)
        end

        def close
          # Release any resources if needed
        end

        protected

        # Override this in subclasses to provide the correct scope name
        def derive_scope_name
          # Default: try to extract from caller or use 'all' as fallback
          # Subclasses should override this method
          'all'
        end

        private

        attr_reader :scope

        def build_scope
          model_class.public_send(scope_name, *scope_params)
        end

        # Override deserialization to reconstruct scope
        def self.from_json(data)
          model_class = Object.const_get(data["model_class"])
          scope_name = data["scope_name"]
          scope = model_class.public_send(scope_name)

          new(
            scope: scope,
            scope_params: data["scope_params"] || []
          )
        end
      end
    end
  end
end

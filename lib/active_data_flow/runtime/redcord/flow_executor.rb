# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Redcord
      # Redcord-specific flow executor.
      # Inherits shared execution logic from Runtime::FlowExecutor.
      # Overrides run_flow to instantiate flow class directly.
      class FlowExecutor < Runtime::FlowExecutor
        private

        # Redcord instantiates the flow class directly from the name.
        #
        # @return [Dry::Monads::Result]
        def run_flow
          flow_class_name = @data_flow.name.camelize
          flow_class = safe_constantize(flow_class_name)

          unless flow_class
            return Failure[:flow_not_found, {
              message: "Flow class #{flow_class_name} not found. " \
                       "Ensure the class is defined and matches the data flow name."
            }]
          end

          flow_instance = flow_class.new
          flow_instance.run
        end

        # Safely converts a string to a constant.
        #
        # @param class_name [String] The class name
        # @return [Class, nil] The class or nil
        def safe_constantize(class_name)
          if class_name.respond_to?(:safe_constantize)
            class_name.safe_constantize
          elsif Object.const_defined?(class_name)
            Object.const_get(class_name)
          end
        rescue NameError
          nil
        end
      end
    end
  end
end

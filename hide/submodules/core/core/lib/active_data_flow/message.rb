# frozen_string_literal: true

module ActiveDataFlow
  # Base module for all message types
  module Message
    # Unconstrained message - any Ruby object
    class Unconstrained
      attr_reader :data

      def initialize(data)
        @data = data
      end

      def to_h
        case data
        when Hash
          data
        else
          { value: data }
        end
      end
    end

    # CloudEvents standard message format
    # See: https://cloudevents.io/
    class CloudEvent
      REQUIRED_ATTRIBUTES = %i[id source specversion type].freeze
      OPTIONAL_ATTRIBUTES = %i[
        datacontenttype dataschema subject time data data_base64
      ].freeze

      attr_reader(*REQUIRED_ATTRIBUTES, *OPTIONAL_ATTRIBUTES)

      def initialize(attributes)
        @attributes = attributes.transform_keys(&:to_sym)
        validate_required_attributes!
        assign_attributes
      end

      def to_h
        @attributes.dup
      end

      def [](key)
        @attributes[key.to_sym]
      end

      private

      def validate_required_attributes!
        REQUIRED_ATTRIBUTES.each do |attr|
          unless @attributes.key?(attr)
            raise ConfigurationError, "Missing required CloudEvent attribute: #{attr}"
          end
        end
      end

      def assign_attributes
        (@attributes.keys & (REQUIRED_ATTRIBUTES + OPTIONAL_ATTRIBUTES)).each do |attr|
          instance_variable_set("@#{attr}", @attributes[attr])
        end
      end
    end

    # CloudEventsLd - Linked Data extension for CloudEvents
    # See: https://github.com/magenticmarketactualskill/cloudeventsld
    class CloudEventLd < CloudEvent
      LINKED_DATA_ATTRIBUTES = %i[@context @id @type].freeze

      def initialize(attributes)
        super
        validate_linked_data_attributes!
      end

      private

      def validate_linked_data_attributes!
        # CloudEventsLd requires JSON-LD context
        unless @attributes.key?(:'@context')
          raise ConfigurationError, "CloudEventLd requires @context attribute"
        end
      end
    end
  end
end

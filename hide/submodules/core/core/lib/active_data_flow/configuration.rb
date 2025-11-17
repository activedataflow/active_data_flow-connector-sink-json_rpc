# frozen_string_literal: true

module ActiveDataFlow
  # Configuration class for validating and accessing configuration values
  class Configuration
    # Initialize with values and attribute definitions
    # @param values [Hash] the configuration values
    # @param attributes [Hash] attribute definitions with types
    def initialize(values, attributes = {})
      @values = symbolize_keys(values)
      @attributes = attributes
      validate!
    end

    # Access configuration value
    # @param key [Symbol] the attribute key
    # @return [Object] the configuration value
    def [](key)
      @values[key]
    end

    # Check if attribute is present
    # @param key [Symbol] the attribute key
    # @return [Boolean] true if present
    def key?(key)
      @values.key?(key)
    end

    # Convert to hash
    # @return [Hash] the configuration as a hash
    def to_h
      @values.dup
    end

    private

    def symbolize_keys(hash)
      return hash unless hash.respond_to?(:transform_keys)
      hash.transform_keys(&:to_sym)
    end

    def validate!
      validate_required_attributes!
      validate_attribute_types!
    end

    def validate_required_attributes!
      @attributes.each do |key, definition|
        next if definition[:optional]
        unless @values.key?(key)
          raise ConfigurationError, "Missing required configuration: #{key}"
        end
      end
    end

    def validate_attribute_types!
      @attributes.each do |key, definition|
        next unless @values.key?(key)
        value = @values[key]
        expected_type = definition[:type]

        unless valid_type?(value, expected_type)
          raise ConfigurationError,
                "Invalid type for #{key}: expected #{expected_type}, got #{value.class}"
        end
      end
    end

    def valid_type?(value, expected_type)
      case expected_type
      when :string
        value.is_a?(String)
      when :integer
        value.is_a?(Integer)
      when :boolean
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      when :hash
        value.is_a?(Hash)
      when :array
        value.is_a?(Array)
      else
        true # Unknown types pass validation
      end
    end
  end
end

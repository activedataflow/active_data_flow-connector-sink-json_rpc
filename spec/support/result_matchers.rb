# frozen_string_literal: true

require "dry/monads"

# RSpec matchers for dry-monads Result types
#
# @example Match any success
#   expect(result).to be_success
#
# @example Match success with specific value
#   expect(result).to be_success(:completed)
#
# @example Match any failure
#   expect(result).to be_failure
#
# @example Match failure with specific type
#   expect(result).to be_failure(:connection_error)
#
RSpec::Matchers.define :be_success do |expected_value|
  match do |actual|
    return false unless actual.is_a?(Dry::Monads::Result::Success)
    return true if expected_value.nil?

    actual.value! == expected_value
  end

  failure_message do |actual|
    if actual.is_a?(Dry::Monads::Result::Failure)
      "expected Success, got Failure(#{actual.failure.inspect})"
    elsif expected_value
      "expected Success(#{expected_value.inspect}), got Success(#{actual.value!.inspect})"
    else
      "expected Success, got #{actual.class}"
    end
  end

  failure_message_when_negated do |actual|
    "expected not to be Success, but got Success(#{actual.value!.inspect})"
  end
end

RSpec::Matchers.define :be_failure do |expected_type|
  match do |actual|
    return false unless actual.is_a?(Dry::Monads::Result::Failure)
    return true if expected_type.nil?

    failure = actual.failure
    failure.is_a?(Array) && failure.first == expected_type
  end

  failure_message do |actual|
    if actual.is_a?(Dry::Monads::Result::Success)
      "expected Failure, got Success(#{actual.value!.inspect})"
    elsif expected_type
      "expected Failure[:#{expected_type}, ...], got Failure(#{actual.failure.inspect})"
    else
      "expected Failure, got #{actual.class}"
    end
  end

  failure_message_when_negated do |actual|
    "expected not to be Failure, but got Failure(#{actual.failure.inspect})"
  end
end

# Helper to extract failure details for assertions
RSpec::Matchers.define :have_failure_message do |expected_message|
  match do |actual|
    return false unless actual.is_a?(Dry::Monads::Result::Failure)

    failure = actual.failure
    failure_data = failure.is_a?(Array) ? failure[1] : failure
    message = failure_data.is_a?(Hash) ? failure_data[:message] : failure_data.to_s

    case expected_message
    when Regexp
      message =~ expected_message
    else
      message == expected_message
    end
  end

  failure_message do |actual|
    failure = actual.failure
    failure_data = failure.is_a?(Array) ? failure[1] : failure
    message = failure_data.is_a?(Hash) ? failure_data[:message] : failure_data.to_s
    "expected failure message #{expected_message.inspect}, got #{message.inspect}"
  end
end

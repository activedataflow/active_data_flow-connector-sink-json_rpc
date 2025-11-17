#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating basic ActiveDataFlow usage

require_relative "../lib/active_data_flow"
require_relative "../lib/active_data_flow/test_helpers"

puts "=" * 60
puts "ActiveDataFlow Core - Basic Usage Example"
puts "=" * 60
puts

# 1. Create messages
puts "1. Creating messages..."
unconstrained = ActiveDataFlow::Message::Unconstrained.new({ id: 1, name: "Test" })
puts "   Unconstrained message: #{unconstrained.to_h.inspect}"

cloud_event = ActiveDataFlow::Message::CloudEvent.new(
  id: "123",
  source: "example-app",
  specversion: "1.0",
  type: "com.example.test",
  data: { message: "Hello World" }
)
puts "   CloudEvent message: #{cloud_event.to_h.inspect}"
puts

# 2. Register test components
puts "2. Registering test components..."
ActiveDataFlow::Registry.register_source(:test, ActiveDataFlow::TestHelpers::TestSource)
ActiveDataFlow::Registry.register_sink(:test, ActiveDataFlow::TestHelpers::TestSink)
puts "   Available sources: #{ActiveDataFlow::Registry.available_sources.inspect}"
puts "   Available sinks: #{ActiveDataFlow::Registry.available_sinks.inspect}"
puts

# 3. Create and run a DataFlow
puts "3. Running a DataFlow..."
flow = ActiveDataFlow::TestHelpers::TestDataFlow.new(
  source: { data: [{ id: 1 }, { id: 2 }, { id: 3 }] },
  sink: {}
)

sink = flow.run
puts "   Processed #{sink.messages.size} messages"
sink.messages.each_with_index do |msg, i|
  puts "   Message #{i + 1}: #{msg.to_h.inspect}"
end
puts

# 4. Test configuration validation
puts "4. Testing configuration validation..."
begin
  ActiveDataFlow::Configuration.new(
    { name: "test" },
    { name: { type: :string }, age: { type: :integer } }
  )
rescue ActiveDataFlow::ConfigurationError => e
  puts "   ✓ Caught expected error: #{e.message}"
end
puts

# 5. Test version compatibility
puts "5. Testing version compatibility..."
compatible = ActiveDataFlow::Version.compatible?("~> 1.0")
puts "   Version #{ActiveDataFlow::VERSION} compatible with ~> 1.0: #{compatible}"
puts

puts "=" * 60
puts "All examples completed successfully!"
puts "=" * 60

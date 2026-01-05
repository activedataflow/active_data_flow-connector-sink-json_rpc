# frozen_string_literal: true

require 'active_data_flow-connector-sink-json_rpc'
require 'webmock/rspec'

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  
  # Disable external connections
  WebMock.disable_net_connect!(allow_localhost: true)
end

require "active_data_flow/version"
require "active_data_flow/engine"

module ActiveDataFlow
  # Configuration for the gem
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :aws_region, :aws_access_key_id, :aws_secret_access_key
    attr_accessor :base_route, :enable_ui, :authorization_method

    def initialize
      @aws_region = ENV['AWS_REGION'] || 'us-east-1'
      @aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
      @aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      @base_route = '/dataflow'
      @enable_ui = true
      @authorization_method = nil
    end
  end
end

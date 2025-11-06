require "rails"
require "active_data_flow/data_flow_base"

module ActiveDataFlow
  class Engine < ::Rails::Engine
    isolate_namespace DataFlowEngine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # Initialize the engine
    initializer "active_data_flow.load_app_instance_data" do |app|
      ActiveDataFlow.setup!
    end

    # Load custom DataFlow objects from host application
    initializer "active_data_flow.load_data_flows", after: :load_config_initializers do |app|
      data_flow_path = Rails.root.join('app', 'data_flow')
      if Dir.exist?(data_flow_path)
        Dir[data_flow_path.join('**', '*.rb')].each do |file|
          require_dependency file
        end
      end
    end

    # Add migrations to host application
    initializer "active_data_flow.append_migrations" do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    # Mount routes
    initializer "active_data_flow.mount_routes" do |app|
      app.routes.append do
        mount ActiveDataFlow::Engine => ActiveDataFlow.configuration.base_route
      end
    end
  end

  def self.setup!
    # Setup AWS credentials
    Aws.config.update(
      region: configuration.aws_region,
      credentials: Aws::Credentials.new(
        configuration.aws_access_key_id,
        configuration.aws_secret_access_key
      )
    ) if configuration.aws_access_key_id && configuration.aws_secret_access_key
  end
end

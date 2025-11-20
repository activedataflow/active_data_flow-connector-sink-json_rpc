# frozen_string_literal: true

require "rails"

module ActiveDataFlow
  class Engine < ::Rails::Engine
    isolate_namespace ActiveDataFlow

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    initializer "active_data_flow.assets" do |app|
      app.config.assets.paths << root.join("app/assets")
      app.config.assets.precompile += %w[active_data_flow_manifest.js]
    end
  end
end

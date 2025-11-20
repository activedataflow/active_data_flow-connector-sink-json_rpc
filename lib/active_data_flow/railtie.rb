# frozen_string_literal: true

module ActiveDataFlow
  class Railtie < Rails::Railtie
    railtie_name :active_data_flow

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end

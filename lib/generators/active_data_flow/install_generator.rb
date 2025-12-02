# frozen_string_literal: true

require 'rails/generators/base'

module ActiveDataFlow
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Creates an ActiveDataFlow initializer file"

      def copy_initializer_file
        template "active_data_flow_initializer.rb", "config/initializers/active_data_flow.rb"
      end
    end
  end
end

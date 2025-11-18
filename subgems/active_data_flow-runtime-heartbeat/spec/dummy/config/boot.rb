# frozen_string_literal: true

# Set the dummy app root
ENV["RAILS_ROOT"] = File.expand_path("..", __dir__)

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../Gemfile", __dir__)

require "bundler/setup"

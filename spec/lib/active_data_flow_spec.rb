# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow do
  it "has a version number" do
    expect(ActiveDataFlow::VERSION).not_to be nil
  end

  it "defines an Engine class" do
    expect(ActiveDataFlow::Engine).to be < Rails::Engine
  end
end

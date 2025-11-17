# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::DataFlow do
  let(:test_flow_class) do
    Class.new do
      include ActiveDataFlow::DataFlow

      def self.configuration_attributes
        { name: { type: :string } }
      end

      def run
        "executed"
      end
    end
  end

  describe ".included" do
    it "extends class with ClassMethods" do
      expect(test_flow_class).to respond_to(:configuration_attributes)
    end
  end

  describe "#initialize" do
    it "creates flow with valid configuration" do
      flow = test_flow_class.new(name: "test")
      expect(flow).to be_a(test_flow_class)
    end

    it "validates configuration" do
      expect {
        test_flow_class.new({})
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Missing required configuration/)
    end
  end

  describe "#run" do
    it "raises NotImplementedError when not implemented" do
      flow_class = Class.new do
        include ActiveDataFlow::DataFlow
      end
      
      flow = flow_class.new
      expect {
        flow.run
      }.to raise_error(NotImplementedError, /must be implemented/)
    end

    it "executes when implemented" do
      flow = test_flow_class.new(name: "test")
      expect(flow.run).to eq("executed")
    end
  end
end

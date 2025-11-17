# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::Configuration do
  describe "#initialize" do
    it "accepts empty configuration" do
      config = described_class.new({}, {})
      expect(config.to_h).to eq({})
    end

    it "symbolizes string keys" do
      config = described_class.new({ "key" => "value" }, {})
      expect(config[:key]).to eq("value")
    end

    it "raises error for missing required attribute" do
      attributes = { name: { type: :string } }
      
      expect {
        described_class.new({}, attributes)
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Missing required configuration: name/)
    end

    it "allows optional attributes to be missing" do
      attributes = { name: { type: :string, optional: true } }
      config = described_class.new({}, attributes)
      expect(config.to_h).to eq({})
    end

    it "validates string type" do
      attributes = { name: { type: :string } }
      
      expect {
        described_class.new({ name: 123 }, attributes)
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Invalid type for name/)
    end

    it "validates integer type" do
      attributes = { count: { type: :integer } }
      
      expect {
        described_class.new({ count: "not a number" }, attributes)
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Invalid type for count/)
    end

    it "validates boolean type" do
      attributes = { enabled: { type: :boolean } }
      config = described_class.new({ enabled: true }, attributes)
      expect(config[:enabled]).to be true
    end
  end

  describe "#[]" do
    it "accesses configuration values" do
      config = described_class.new({ key: "value" }, {})
      expect(config[:key]).to eq("value")
    end
  end

  describe "#key?" do
    it "checks if key exists" do
      config = described_class.new({ key: "value" }, {})
      expect(config.key?(:key)).to be true
      expect(config.key?(:missing)).to be false
    end
  end

  describe "#to_h" do
    it "returns configuration as hash" do
      values = { key: "value", count: 42 }
      config = described_class.new(values, {})
      expect(config.to_h).to eq(values)
    end
  end
end

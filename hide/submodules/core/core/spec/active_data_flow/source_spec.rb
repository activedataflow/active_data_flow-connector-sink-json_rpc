# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::Source do
  let(:test_source_class) do
    Class.new(described_class) do
      def self.configuration_attributes
        { data: { type: :array } }
      end

      def each
        configuration[:data].each do |item|
          yield ActiveDataFlow::Message::Unconstrained.new(item)
        end
      end
    end
  end

  describe "#initialize" do
    it "creates source with valid configuration" do
      source = test_source_class.new(data: [1, 2, 3])
      expect(source).to be_a(described_class)
    end

    it "validates configuration attributes" do
      expect {
        test_source_class.new({})
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Missing required configuration/)
    end
  end

  describe "#each" do
    it "raises NotImplementedError in base class" do
      source = described_class.new({})
      expect {
        source.each { |msg| msg }
      }.to raise_error(NotImplementedError, /must be implemented/)
    end

    it "yields messages in subclass" do
      source = test_source_class.new(data: [{ id: 1 }, { id: 2 }])
      messages = []
      source.each { |msg| messages << msg }
      
      expect(messages.size).to eq(2)
      expect(messages.first).to be_a(ActiveDataFlow::Message::Unconstrained)
    end
  end
end

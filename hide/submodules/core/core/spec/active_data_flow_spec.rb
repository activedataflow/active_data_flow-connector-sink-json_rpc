# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow do
  let(:test_source_class) do
    Class.new(ActiveDataFlow::Source) do
      def each
        yield ActiveDataFlow::Message::Unconstrained.new({ test: true })
      end
    end
  end

  let(:test_sink_class) do
    Class.new(ActiveDataFlow::Sink) do
      def write(message)
        # no-op
      end
    end
  end

  before do
    ActiveDataFlow::Registry.register_source(:test, test_source_class)
    ActiveDataFlow::Registry.register_sink(:test, test_sink_class)
  end

  describe ".source" do
    it "creates source from registry" do
      source = described_class.source(:test, {})
      expect(source).to be_a(test_source_class)
    end

    it "raises error for unknown source type" do
      expect {
        described_class.source(:unknown, {})
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Unknown source type/)
    end
  end

  describe ".sink" do
    it "creates sink from registry" do
      sink = described_class.sink(:test, {})
      expect(sink).to be_a(test_sink_class)
    end

    it "raises error for unknown sink type" do
      expect {
        described_class.sink(:unknown, {})
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Unknown sink type/)
    end
  end
end

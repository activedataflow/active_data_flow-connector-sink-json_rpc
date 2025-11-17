# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::Registry do
  # Create test classes
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

  let(:invalid_source_class) { Class.new }

  describe ".register_source" do
    it "registers a valid source class" do
      described_class.register_source(:test_source, test_source_class)
      expect(described_class.available_sources).to include(:test_source)
    end

    it "raises error for invalid source class" do
      expect {
        described_class.register_source(:invalid, invalid_source_class)
      }.to raise_error(ArgumentError, /must inherit from ActiveDataFlow::Source/)
    end
  end

  describe ".register_sink" do
    it "registers a valid sink class" do
      described_class.register_sink(:test_sink, test_sink_class)
      expect(described_class.available_sinks).to include(:test_sink)
    end

    it "raises error for invalid sink class" do
      expect {
        described_class.register_sink(:invalid, invalid_source_class)
      }.to raise_error(ArgumentError, /must inherit from ActiveDataFlow::Sink/)
    end
  end

  describe ".source" do
    before do
      described_class.register_source(:registered, test_source_class)
    end

    it "returns registered source class" do
      expect(described_class.source(:registered)).to eq(test_source_class)
    end

    it "raises error for unknown source type" do
      expect {
        described_class.source(:unknown)
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Unknown source type: unknown/)
    end
  end

  describe ".sink" do
    before do
      described_class.register_sink(:registered, test_sink_class)
    end

    it "returns registered sink class" do
      expect(described_class.sink(:registered)).to eq(test_sink_class)
    end

    it "raises error for unknown sink type" do
      expect {
        described_class.sink(:unknown)
      }.to raise_error(ActiveDataFlow::ConfigurationError, /Unknown sink type: unknown/)
    end
  end

  describe ".available_sources" do
    it "lists registered source types" do
      described_class.register_source(:source1, test_source_class)
      expect(described_class.available_sources).to include(:source1)
    end
  end

  describe ".available_sinks" do
    it "lists registered sink types" do
      described_class.register_sink(:sink1, test_sink_class)
      expect(described_class.available_sinks).to include(:sink1)
    end
  end
end

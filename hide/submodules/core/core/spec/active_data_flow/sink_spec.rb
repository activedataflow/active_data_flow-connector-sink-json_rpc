# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::Sink do
  let(:test_sink_class) do
    Class.new(described_class) do
      attr_reader :messages

      def initialize(configuration)
        super
        @messages = []
      end

      def write(message)
        @messages << message
      end
    end
  end

  describe "#initialize" do
    it "creates sink with configuration" do
      sink = test_sink_class.new({})
      expect(sink).to be_a(described_class)
    end
  end

  describe "#write" do
    it "raises NotImplementedError in base class" do
      sink = described_class.new({})
      message = ActiveDataFlow::Message::Unconstrained.new({ test: true })
      
      expect {
        sink.write(message)
      }.to raise_error(NotImplementedError, /must be implemented/)
    end

    it "writes messages in subclass" do
      sink = test_sink_class.new({})
      message = ActiveDataFlow::Message::Unconstrained.new({ id: 1 })
      
      sink.write(message)
      expect(sink.messages).to include(message)
    end
  end

  describe "#flush" do
    it "has default no-op implementation" do
      sink = described_class.new({})
      expect { sink.flush }.not_to raise_error
    end
  end

  describe "#close" do
    it "has default no-op implementation" do
      sink = described_class.new({})
      expect { sink.close }.not_to raise_error
    end
  end
end

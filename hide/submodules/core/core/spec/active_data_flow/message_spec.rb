# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::Message do
  describe ActiveDataFlow::Message::Unconstrained do
    describe "#initialize" do
      it "stores the data" do
        data = { key: "value" }
        message = described_class.new(data)
        expect(message.data).to eq(data)
      end
    end

    describe "#to_h" do
      it "returns hash data as-is" do
        data = { key: "value" }
        message = described_class.new(data)
        expect(message.to_h).to eq(data)
      end

      it "wraps non-hash data in value key" do
        message = described_class.new("test")
        expect(message.to_h).to eq({ value: "test" })
      end
    end
  end

  describe ActiveDataFlow::Message::CloudEvent do
    let(:valid_attributes) do
      {
        id: "123",
        source: "test-source",
        specversion: "1.0",
        type: "com.example.test"
      }
    end

    describe "#initialize" do
      it "creates a valid CloudEvent with required attributes" do
        event = described_class.new(valid_attributes)
        expect(event.id).to eq("123")
        expect(event.source).to eq("test-source")
        expect(event.specversion).to eq("1.0")
        expect(event.type).to eq("com.example.test")
      end

      it "raises error when missing required attribute" do
        invalid_attributes = valid_attributes.dup
        invalid_attributes.delete(:id)
        
        expect {
          described_class.new(invalid_attributes)
        }.to raise_error(ActiveDataFlow::ConfigurationError, /Missing required CloudEvent attribute: id/)
      end

      it "accepts optional attributes" do
        attributes = valid_attributes.merge(data: { message: "hello" })
        event = described_class.new(attributes)
        expect(event.data).to eq({ message: "hello" })
      end
    end

    describe "#to_h" do
      it "returns all attributes as hash" do
        event = described_class.new(valid_attributes)
        expect(event.to_h).to eq(valid_attributes)
      end
    end

    describe "#[]" do
      it "accesses attributes by key" do
        event = described_class.new(valid_attributes)
        expect(event[:id]).to eq("123")
        expect(event[:source]).to eq("test-source")
      end
    end
  end

  describe ActiveDataFlow::Message::CloudEventLd do
    let(:valid_attributes) do
      {
        id: "123",
        source: "test-source",
        specversion: "1.0",
        type: "com.example.test",
        :'@context' => "https://example.com/context"
      }
    end

    describe "#initialize" do
      it "creates a valid CloudEventLd with @context" do
        event = described_class.new(valid_attributes)
        expect(event.id).to eq("123")
        expect(event[:'@context']).to eq("https://example.com/context")
      end

      it "raises error when missing @context" do
        invalid_attributes = valid_attributes.dup
        invalid_attributes.delete(:'@context')
        
        expect {
          described_class.new(invalid_attributes)
        }.to raise_error(ActiveDataFlow::ConfigurationError, /CloudEventLd requires @context attribute/)
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default storage_backend to :active_record" do
      expect(config.storage_backend).to eq(:active_record)
    end

    it "sets default redis_config to empty hash" do
      expect(config.redis_config).to eq({})
    end

    it "sets default auto_load_data_flows to true" do
      expect(config.auto_load_data_flows).to be true
    end

    it "sets default log_level to :info" do
      expect(config.log_level).to eq(:info)
    end

    it "sets default data_flows_path to app/data_flows" do
      expect(config.data_flows_path).to eq("app/data_flows")
    end
  end

  describe "#validate_storage_backend!" do
    context "with supported backends" do
      it "accepts :active_record" do
        config.storage_backend = :active_record
        expect { config.validate_storage_backend! }.not_to raise_error
      end

      it "accepts :redcord_redis" do
        config.storage_backend = :redcord_redis
        expect { config.validate_storage_backend! }.not_to raise_error
      end

      it "accepts :redcord_redis_emulator" do
        config.storage_backend = :redcord_redis_emulator
        expect { config.validate_storage_backend! }.not_to raise_error
      end
    end

    # Feature: configurable-storage-backend, Property 1: Configuration validation
    context "with unsupported backends" do
      let(:invalid_backends) { [:mysql, :postgres, :mongodb, :invalid, :foo, :bar, :redis, :memcached] }

      it "rejects all unsupported storage backends with clear error message" do
        invalid_backends.each do |backend|
          config.storage_backend = backend
          expect { config.validate_storage_backend! }.to raise_error(
            ActiveDataFlow::ConfigurationError,
            /Unsupported storage backend: #{backend}.*Supported backends:/
          )
        end
      end

      it "includes list of supported backends in error message" do
        config.storage_backend = :invalid
        expect { config.validate_storage_backend! }.to raise_error(
          ActiveDataFlow::ConfigurationError,
          /active_record.*redcord_redis.*redcord_redis_emulator/
        )
      end
    end
  end

  describe "#active_record?" do
    it "returns true when storage_backend is :active_record" do
      config.storage_backend = :active_record
      expect(config.active_record?).to be true
    end

    it "returns false when storage_backend is :redcord_redis" do
      config.storage_backend = :redcord_redis
      expect(config.active_record?).to be false
    end

    it "returns false when storage_backend is :redcord_redis_emulator" do
      config.storage_backend = :redcord_redis_emulator
      expect(config.active_record?).to be false
    end
  end

  describe "#redcord?" do
    it "returns false when storage_backend is :active_record" do
      config.storage_backend = :active_record
      expect(config.redcord?).to be false
    end

    it "returns true when storage_backend is :redcord_redis" do
      config.storage_backend = :redcord_redis
      expect(config.redcord?).to be true
    end

    it "returns true when storage_backend is :redcord_redis_emulator" do
      config.storage_backend = :redcord_redis_emulator
      expect(config.redcord?).to be true
    end
  end

  describe "#redcord_redis?" do
    it "returns false when storage_backend is :active_record" do
      config.storage_backend = :active_record
      expect(config.redcord_redis?).to be false
    end

    it "returns true when storage_backend is :redcord_redis" do
      config.storage_backend = :redcord_redis
      expect(config.redcord_redis?).to be true
    end

    it "returns false when storage_backend is :redcord_redis_emulator" do
      config.storage_backend = :redcord_redis_emulator
      expect(config.redcord_redis?).to be false
    end
  end

  describe "#redcord_redis_emulator?" do
    it "returns false when storage_backend is :active_record" do
      config.storage_backend = :active_record
      expect(config.redcord_redis_emulator?).to be false
    end

    it "returns false when storage_backend is :redcord_redis" do
      config.storage_backend = :redcord_redis
      expect(config.redcord_redis_emulator?).to be false
    end

    it "returns true when storage_backend is :redcord_redis_emulator" do
      config.storage_backend = :redcord_redis_emulator
      expect(config.redcord_redis_emulator?).to be true
    end
  end
end

RSpec.describe ActiveDataFlow do
  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(ActiveDataFlow::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".configure" do
    after do
      ActiveDataFlow.reset_configuration!
    end

    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(ActiveDataFlow::Configuration)
    end

    it "allows setting storage_backend" do
      described_class.configure do |config|
        config.storage_backend = :redcord_redis
      end
      expect(described_class.configuration.storage_backend).to eq(:redcord_redis)
    end

    it "allows setting redis_config" do
      redis_config = { url: "redis://localhost:6379/0" }
      described_class.configure do |config|
        config.redis_config = redis_config
      end
      expect(described_class.configuration.redis_config).to eq(redis_config)
    end
  end

  describe ".reset_configuration!" do
    it "resets configuration to defaults" do
      described_class.configure do |config|
        config.storage_backend = :redcord_redis
        config.redis_config = { url: "redis://localhost:6379/0" }
      end

      described_class.reset_configuration!

      expect(described_class.configuration.storage_backend).to eq(:active_record)
      expect(described_class.configuration.redis_config).to eq({})
    end
  end
end

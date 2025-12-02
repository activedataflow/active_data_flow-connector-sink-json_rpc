# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::StorageBackendLoader do
  describe ".validate_dependencies!" do
    context "with :active_record backend" do
      before do
        ActiveDataFlow.configure do |config|
          config.storage_backend = :active_record
        end
      end

      after do
        ActiveDataFlow.reset_configuration!
      end

      it "does not raise error" do
        expect { described_class.validate_dependencies! }.not_to raise_error
      end
    end

    context "with :redcord_redis backend" do
      before do
        ActiveDataFlow.configure do |config|
          config.storage_backend = :redcord_redis
        end
      end

      after do
        ActiveDataFlow.reset_configuration!
      end

      it "raises DependencyError if redcord gem is not available" do
        allow(described_class).to receive(:require).with("redcord").and_raise(LoadError)

        expect { described_class.validate_dependencies! }.to raise_error(
          ActiveDataFlow::DependencyError,
          /redcord.*gem.*required/
        )
      end
    end

    context "with :redcord_redis_emulator backend" do
      before do
        ActiveDataFlow.configure do |config|
          config.storage_backend = :redcord_redis_emulator
        end
      end

      after do
        ActiveDataFlow.reset_configuration!
      end

      it "raises DependencyError if redis-emulator gem is not available" do
        allow(described_class).to receive(:require).with("redcord").and_return(true)
        allow(described_class).to receive(:require).with("redis/emulator").and_raise(LoadError)

        expect { described_class.validate_dependencies! }.to raise_error(
          ActiveDataFlow::DependencyError,
          /redis-emulator.*gem.*required/
        )
      end
    end
  end

  describe ".log_configuration" do
    let(:logger) { instance_double(Logger) }

    before do
      allow(Rails).to receive(:logger).and_return(logger) if defined?(Rails)
    end

    after do
      ActiveDataFlow.reset_configuration!
    end

    it "logs storage backend configuration" do
      ActiveDataFlow.configure do |config|
        config.storage_backend = :active_record
      end

      expect(logger).to receive(:info).with(/Storage backend: active_record/)

      described_class.send(:log_configuration)
    end

    context "with redcord_redis backend" do
      it "logs Redis configuration" do
        ActiveDataFlow.configure do |config|
          config.storage_backend = :redcord_redis
          config.redis_config = { url: "redis://localhost:6379/0" }
        end

        expect(logger).to receive(:info).with(/Storage backend: redcord_redis/)
        expect(logger).to receive(:info).with(/Redis config:/)

        described_class.send(:log_configuration)
      end
    end

    context "with redcord_redis_emulator backend" do
      it "logs Redis Emulator usage" do
        ActiveDataFlow.configure do |config|
          config.storage_backend = :redcord_redis_emulator
        end

        expect(logger).to receive(:info).with(/Storage backend: redcord_redis_emulator/)
        expect(logger).to receive(:info).with(/Redis Emulator with Rails\.cache/)

        described_class.send(:log_configuration)
      end
    end
  end

  # Feature: configurable-storage-backend, Property 2: Backend-specific model loading
  describe "backend-specific model loading property" do
    after do
      ActiveDataFlow.reset_configuration!
    end

    [:active_record, :redcord_redis, :redcord_redis_emulator].each do |backend|
      context "with #{backend} backend" do
        it "validates the correct backend is configured" do
          ActiveDataFlow.configure do |config|
            config.storage_backend = backend
          end

          expect(ActiveDataFlow.configuration.storage_backend).to eq(backend)
        end

        it "validates storage backend without error" do
          ActiveDataFlow.configure do |config|
            config.storage_backend = backend
          end

          expect { ActiveDataFlow.configuration.validate_storage_backend! }.not_to raise_error
        end
      end
    end
  end

  describe ".initialize_redis_connection" do
    let(:redis_client) { instance_double(Redis) }
    let(:redcord_config) { double("Redcord::Config") }
    let(:redcord_class) { double("Redcord") }

    before do
      stub_const("Redcord", redcord_class)
      allow(Redis).to receive(:new).and_return(redis_client)
      allow(redis_client).to receive(:ping).and_return("PONG")
      allow(redcord_class).to receive(:configure).and_yield(redcord_config)
      allow(redcord_config).to receive(:redis=)
    end

    context "with URL configuration" do
      it "creates Redis client with URL" do
        ActiveDataFlow.configure do |config|
          config.redis_config = { url: "redis://example.com:6379/1" }
        end

        expect(Redis).to receive(:new).with(
          url: "redis://example.com:6379/1",
          host: nil,
          port: nil,
          db: nil
        ).and_return(redis_client)

        described_class.initialize_redis_connection
      end
    end

    context "with host/port/db configuration" do
      it "creates Redis client with individual options" do
        ActiveDataFlow.configure do |config|
          config.redis_config = { host: "localhost", port: 6380, db: 2 }
        end

        expect(Redis).to receive(:new).with(
          url: "redis://localhost:6379/0",
          host: "localhost",
          port: 6380,
          db: 2
        ).and_return(redis_client)

        described_class.initialize_redis_connection
      end
    end

    context "with default configuration" do
      it "uses default Redis URL" do
        ActiveDataFlow.configure do |config|
          config.redis_config = {}
        end

        expect(Redis).to receive(:new).with(
          url: "redis://localhost:6379/0",
          host: nil,
          port: nil,
          db: nil
        ).and_return(redis_client)

        described_class.initialize_redis_connection
      end
    end

    context "when connection fails" do
      it "raises ConnectionError with clear message" do
        allow(redis_client).to receive(:ping).and_raise(Redis::CannotConnectError.new("Connection refused"))

        expect { described_class.initialize_redis_connection }.to raise_error(
          ActiveDataFlow::ConnectionError,
          /Failed to connect to Redis.*Connection refused/
        )
      end
    end
  end

  describe ".initialize_redis_emulator" do
    let(:redis_emulator) { double("Redis::Emulator") }
    let(:redis_emulator_class) { double("Redis::Emulator Class") }
    let(:redcord_config) { double("Redcord::Config") }
    let(:redcord_class) { double("Redcord") }
    let(:rails_cache) { double("ActiveSupport::Cache::Store") }

    before do
      stub_const("Redis::Emulator", redis_emulator_class)
      stub_const("Redcord", redcord_class)
      allow(redis_emulator_class).to receive(:new).and_return(redis_emulator)
      allow(Rails).to receive(:cache).and_return(rails_cache)
      allow(redcord_class).to receive(:configure).and_yield(redcord_config)
      allow(redcord_config).to receive(:redis=)
    end

    it "creates Redis::Emulator with Rails.cache backend" do
      expect(redis_emulator_class).to receive(:new).with(backend: rails_cache)

      described_class.initialize_redis_emulator
    end

    it "configures Redcord to use Redis::Emulator" do
      expect(redcord_config).to receive(:redis=).with(redis_emulator)

      described_class.initialize_redis_emulator
    end

    it "does not validate connectivity" do
      expect(redis_emulator).not_to receive(:ping)

      described_class.initialize_redis_emulator
    end
  end
end

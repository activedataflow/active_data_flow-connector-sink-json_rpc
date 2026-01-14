# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::ActiveRecord::DataFlow do
  describe "class configuration" do
    it "uses the correct table name" do
      expect(described_class.table_name).to eq("active_data_flow_data_flows")
    end

    it "has correct model name for routing" do
      expect(described_class.model_name.singular).to eq("data_flow")
      expect(described_class.model_name.route_key).to eq("data_flows")
    end
  end

  describe "required methods" do
    let(:instance) { described_class.new }

    it "responds to find_or_create" do
      expect(described_class).to respond_to(:find_or_create)
    end

    it "responds to interval_seconds" do
      expect(instance).to respond_to(:interval_seconds)
    end

    it "responds to enabled?" do
      expect(instance).to respond_to(:enabled?)
    end

    it "responds to run_one" do
      expect(instance).to respond_to(:run_one)
    end

    it "responds to run_batch" do
      expect(instance).to respond_to(:run_batch)
    end

    it "responds to next_due_run" do
      expect(instance).to respond_to(:next_due_run)
    end

    it "responds to schedule_next_run" do
      expect(instance).to respond_to(:schedule_next_run)
    end

    it "responds to mark_run_started!" do
      expect(instance).to respond_to(:mark_run_started!)
    end

    it "responds to mark_run_completed!" do
      expect(instance).to respond_to(:mark_run_completed!)
    end

    it "responds to mark_run_failed!" do
      expect(instance).to respond_to(:mark_run_failed!)
    end

    it "responds to run" do
      expect(instance).to respond_to(:run)
    end

    it "responds to heartbeat_event" do
      expect(instance).to respond_to(:heartbeat_event)
    end
  end

  describe "scopes" do
    it "has active scope" do
      expect(described_class).to respond_to(:active)
    end

    it "has inactive scope" do
      expect(described_class).to respond_to(:inactive)
    end

    it "has due_to_run scope" do
      expect(described_class).to respond_to(:due_to_run)
    end
  end

  describe "#interval_seconds" do
    it "returns default interval when runtime is nil" do
      data_flow = described_class.new
      expect(data_flow.interval_seconds).to eq(3600)
    end

    it "returns runtime interval when set" do
      data_flow = described_class.new(runtime: { 'interval' => 120 })
      expect(data_flow.interval_seconds).to eq(120)
    end
  end

  describe "#enabled?" do
    it "returns false when runtime is nil" do
      data_flow = described_class.new
      expect(data_flow.enabled?).to be false
    end

    it "returns true when runtime enabled is true" do
      data_flow = described_class.new(runtime: { 'enabled' => true })
      expect(data_flow.enabled?).to be true
    end

    it "returns false when runtime enabled is false" do
      data_flow = described_class.new(runtime: { 'enabled' => false })
      expect(data_flow.enabled?).to be false
    end
  end
end

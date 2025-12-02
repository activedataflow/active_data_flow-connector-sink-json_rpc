# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveDataFlow::ActiveRecord::DataFlowRun do
  describe "class configuration" do
    it "uses the correct table name" do
      expect(described_class.table_name).to eq("active_data_flow_data_flow_runs")
    end

    it "has correct model name for routing" do
      expect(described_class.model_name.name).to eq("ActiveDataFlow::DataFlowRun")
    end
  end

  describe "required methods" do
    let(:instance) { described_class.new }

    it "responds to pending?" do
      expect(instance).to respond_to(:pending?)
    end

    it "responds to in_progress?" do
      expect(instance).to respond_to(:in_progress?)
    end

    it "responds to success?" do
      expect(instance).to respond_to(:success?)
    end

    it "responds to failed?" do
      expect(instance).to respond_to(:failed?)
    end

    it "responds to cancelled?" do
      expect(instance).to respond_to(:cancelled?)
    end

    it "responds to completed?" do
      expect(instance).to respond_to(:completed?)
    end

    it "responds to due?" do
      expect(instance).to respond_to(:due?)
    end

    it "responds to overdue?" do
      expect(instance).to respond_to(:overdue?)
    end

    it "responds to start!" do
      expect(instance).to respond_to(:start!)
    end

    it "responds to complete!" do
      expect(instance).to respond_to(:complete!)
    end

    it "responds to fail!" do
      expect(instance).to respond_to(:fail!)
    end

    it "responds to duration" do
      expect(instance).to respond_to(:duration)
    end
  end

  describe "scopes" do
    it "has due_to_run scope" do
      expect(described_class).to respond_to(:due_to_run)
    end

    it "has pending scope" do
      expect(described_class).to respond_to(:pending)
    end

    it "has in_progress scope" do
      expect(described_class).to respond_to(:in_progress)
    end

    it "has success scope" do
      expect(described_class).to respond_to(:success)
    end

    it "has completed scope" do
      expect(described_class).to respond_to(:completed)
    end

    it "has due scope" do
      expect(described_class).to respond_to(:due)
    end

    it "has overdue scope" do
      expect(described_class).to respond_to(:overdue)
    end
  end

  describe "status methods" do
    it "pending? returns true when status is pending" do
      run = described_class.new(status: 'pending')
      expect(run.pending?).to be true
    end

    it "in_progress? returns true when status is in_progress" do
      run = described_class.new(status: 'in_progress')
      expect(run.in_progress?).to be true
    end

    it "success? returns true when status is success" do
      run = described_class.new(status: 'success')
      expect(run.success?).to be true
    end

    it "failed? returns true when status is failed" do
      run = described_class.new(status: 'failed')
      expect(run.failed?).to be true
    end

    it "cancelled? returns true when status is cancelled" do
      run = described_class.new(status: 'cancelled')
      expect(run.cancelled?).to be true
    end

    it "completed? returns true when status is success" do
      run = described_class.new(status: 'success')
      expect(run.completed?).to be true
    end

    it "completed? returns true when status is failed" do
      run = described_class.new(status: 'failed')
      expect(run.completed?).to be true
    end

    it "completed? returns false when status is pending" do
      run = described_class.new(status: 'pending')
      expect(run.completed?).to be false
    end
  end

  describe "#duration" do
    it "returns nil when started_at is nil" do
      run = described_class.new
      expect(run.duration).to be_nil
    end

    it "returns nil when ended_at is nil" do
      run = described_class.new(started_at: Time.current)
      expect(run.duration).to be_nil
    end

    it "returns duration when both timestamps are set" do
      started = Time.current
      ended = started + 60
      run = described_class.new(started_at: started, ended_at: ended)
      expect(run.duration).to eq(60)
    end
  end
end

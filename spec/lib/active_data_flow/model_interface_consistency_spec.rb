# frozen_string_literal: true

require "spec_helper"

# Feature: configurable-storage-backend, Property 3: Model interface consistency
RSpec.describe "Model interface consistency property" do
  let(:required_data_flow_methods) do
    [
      :find_or_create, :interval_seconds, :enabled?, :run_one, :run_batch,
      :next_due_run, :schedule_next_run, :mark_run_started!,
      :mark_run_completed!, :mark_run_failed!, :run, :heartbeat_event
    ]
  end

  let(:required_data_flow_run_methods) do
    [
      :pending?, :in_progress?, :success?, :failed?,
      :cancelled?, :completed?, :due?, :overdue?,
      :start!, :complete!, :fail!, :duration
    ]
  end

  let(:required_data_flow_scopes) do
    [:active, :inactive, :due_to_run]
  end

  let(:required_data_flow_run_scopes) do
    [:due_to_run, :pending, :in_progress, :success, :completed, :due, :overdue]
  end

  describe "ActiveRecord backend" do
    let(:data_flow_class) { ActiveDataFlow::ActiveRecord::DataFlow }
    let(:data_flow_run_class) { ActiveDataFlow::ActiveRecord::DataFlowRun }

    context "DataFlow model" do
      it "responds to all required instance methods" do
        instance = data_flow_class.new
        required_data_flow_methods.each do |method|
          expect(instance).to respond_to(method), "Expected DataFlow to respond to #{method}"
        end
      end

      it "responds to all required class methods (scopes)" do
        required_data_flow_scopes.each do |scope|
          expect(data_flow_class).to respond_to(scope), "Expected DataFlow to respond to scope #{scope}"
        end
      end

      it "has find_or_create class method" do
        expect(data_flow_class).to respond_to(:find_or_create)
      end
    end

    context "DataFlowRun model" do
      it "responds to all required instance methods" do
        instance = data_flow_run_class.new
        required_data_flow_run_methods.each do |method|
          expect(instance).to respond_to(method), "Expected DataFlowRun to respond to #{method}"
        end
      end

      it "responds to all required class methods (scopes)" do
        required_data_flow_run_scopes.each do |scope|
          expect(data_flow_run_class).to respond_to(scope), "Expected DataFlowRun to respond to scope #{scope}"
        end
      end
    end
  end

  describe "Redcord backend" do
    let(:data_flow_class) { ActiveDataFlow::Redcord::DataFlow }
    let(:data_flow_run_class) { ActiveDataFlow::Redcord::DataFlowRun }

    before do
      # Stub Redcord::Base to allow loading the models
      unless defined?(::Redcord)
        redcord_base = Module.new do
          def self.included(base)
            base.extend(ClassMethods)
            base.class_eval do
              def self.attribute(name, type); end
              def self.range_index(name); end
              def self.validates(*args); end
              def self.where(conditions); []; end
              def self.find(id); new; end
              def self.find_by(conditions); nil; end
              def self.all; []; end
              def self.create!(**attrs); new; end
              def save!; true; end
              def id; "test-id"; end
            end
          end

          module ClassMethods
            def new(*args)
              obj = allocate
              obj.send(:initialize, *args)
              obj
            end
          end
        end

        stub_const("Redcord::Base", redcord_base)
      end

      # Load the Redcord models
      require_relative "../../../app/models/active_data_flow/redcord/data_flow"
      require_relative "../../../app/models/active_data_flow/redcord/data_flow_run"
    end

    context "DataFlow model" do
      it "responds to all required instance methods" do
        instance = data_flow_class.new
        required_data_flow_methods.each do |method|
          expect(instance).to respond_to(method), "Expected DataFlow to respond to #{method}"
        end
      end

      it "responds to all required class methods (scopes)" do
        required_data_flow_scopes.each do |scope|
          expect(data_flow_class).to respond_to(scope), "Expected DataFlow to respond to scope #{scope}"
        end
      end

      it "has find_or_create class method" do
        expect(data_flow_class).to respond_to(:find_or_create)
      end
    end

    context "DataFlowRun model" do
      it "responds to all required instance methods" do
        instance = data_flow_run_class.new
        required_data_flow_run_methods.each do |method|
          expect(instance).to respond_to(method), "Expected DataFlowRun to respond to #{method}"
        end
      end

      it "responds to all required class methods (scopes)" do
        required_data_flow_run_scopes.each do |scope|
          expect(data_flow_run_class).to respond_to(scope), "Expected DataFlowRun to respond to scope #{scope}"
        end
      end
    end
  end

  describe "Interface consistency across backends" do
    let(:backends) do
      [
        { name: :active_record, data_flow: ActiveDataFlow::ActiveRecord::DataFlow, data_flow_run: ActiveDataFlow::ActiveRecord::DataFlowRun },
        { name: :redcord, data_flow: ActiveDataFlow::Redcord::DataFlow, data_flow_run: ActiveDataFlow::Redcord::DataFlowRun }
      ]
    end

    before do
      # Stub Redcord for consistency test
      unless defined?(::Redcord)
        redcord_base = Module.new do
          def self.included(base)
            base.extend(ClassMethods)
            base.class_eval do
              def self.attribute(name, type); end
              def self.range_index(name); end
              def self.validates(*args); end
              def self.where(conditions); []; end
              def self.find(id); new; end
              def self.find_by(conditions); nil; end
              def self.all; []; end
              def self.create!(**attrs); new; end
              def save!; true; end
              def id; "test-id"; end
            end
          end

          module ClassMethods
            def new(*args)
              obj = allocate
              obj.send(:initialize, *args)
              obj
            end
          end
        end

        stub_const("Redcord::Base", redcord_base)
      end

      require_relative "../../../app/models/active_data_flow/redcord/data_flow"
      require_relative "../../../app/models/active_data_flow/redcord/data_flow_run"
    end

    it "all backends provide the same DataFlow interface" do
      backends.each do |backend|
        instance = backend[:data_flow].new
        required_data_flow_methods.each do |method|
          expect(instance).to respond_to(method),
                             "Expected #{backend[:name]} DataFlow to respond to #{method}"
        end
      end
    end

    it "all backends provide the same DataFlowRun interface" do
      backends.each do |backend|
        instance = backend[:data_flow_run].new
        required_data_flow_run_methods.each do |method|
          expect(instance).to respond_to(method),
                             "Expected #{backend[:name]} DataFlowRun to respond to #{method}"
        end
      end
    end

    it "all backends provide the same DataFlow scopes" do
      backends.each do |backend|
        required_data_flow_scopes.each do |scope|
          expect(backend[:data_flow]).to respond_to(scope),
                                         "Expected #{backend[:name]} DataFlow to respond to scope #{scope}"
        end
      end
    end

    it "all backends provide the same DataFlowRun scopes" do
      backends.each do |backend|
        required_data_flow_run_scopes.each do |scope|
          expect(backend[:data_flow_run]).to respond_to(scope),
                                             "Expected #{backend[:name]} DataFlowRun to respond to scope #{scope}"
        end
      end
    end
  end
end

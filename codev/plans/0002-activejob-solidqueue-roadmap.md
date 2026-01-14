# Implementation Plan 0002: ActiveJob & SolidQueue Integration - Phase 1

## Phase 1: ActiveJob Runtime Foundation

This plan details the implementation of the core ActiveJob runtime that will serve as the foundation for SolidQueue integration.

---

## Current State Analysis

### Existing Runtime Architecture
- `Runtime::Base` (`lib/active_data_flow/runtime/base.rb:5-46`)
  - Attributes: `batch_size`, `enabled`, `interval`, `options`
  - Methods: `execute`, `transform`, `as_json`, `from_json`

- `Runtime::FlowExecutor` (`lib/active_data_flow/runtime/flow_executor.rb:7-73`)
  - Handles lifecycle: mark started → run → mark completed/failed
  - Returns `Dry::Monads::Result` (Success/Failure)

- `Heartbeat::ScheduleFlowRuns` (`lib/active_data_flow/runtime/heartbeat/schedule_flow_runs.rb`)
  - Polls `DataFlowRun.due_to_run` and executes each

### Integration Points
- `DataFlow` model has `schedule_next_run`, `mark_run_started!`, etc.
- Runs tracked via `DataFlowRun` with statuses: pending, in_progress, success, failed
- Configuration supports multiple storage backends

---

## Implementation Tasks

### Task 1: Create DataFlowJob

**File**: `app/jobs/active_data_flow/data_flow_job.rb`

```ruby
# frozen_string_literal: true

module ActiveDataFlow
  class DataFlowJob < ApplicationJob
    queue_as :active_data_flow

    # Prevent concurrent execution of the same flow
    # Note: limits_concurrency requires SolidQueue
    if respond_to?(:limits_concurrency)
      limits_concurrency key: ->(data_flow_id, **) { "data_flow:#{data_flow_id}" }
    end

    # Retry configuration
    retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError

    after_discard do |job, error|
      Rails.logger.error "[DataFlowJob] Discarded: #{error.message}"
    end

    def perform(data_flow_id, run_id: nil)
      data_flow = resolve_data_flow(data_flow_id)
      return unless data_flow&.enabled?

      # Create or find the run record
      data_flow_run = find_or_create_run(data_flow, run_id)

      # Delegate to FlowExecutor
      ActiveDataFlow::Runtime::FlowExecutor.execute(data_flow_run)
    end

    private

    def resolve_data_flow(data_flow_id)
      if data_flow_id.is_a?(GlobalID) || data_flow_id.to_s.start_with?("gid://")
        GlobalID::Locator.locate(data_flow_id)
      else
        ActiveDataFlow::DataFlow.find_by(id: data_flow_id)
      end
    end

    def find_or_create_run(data_flow, run_id)
      if run_id
        data_flow.data_flow_runs.find(run_id)
      else
        data_flow.data_flow_runs.create!(
          status: 'pending',
          run_after: Time.current
        )
      end
    end
  end
end
```

**Rationale**:
- Uses `data_flow_id` instead of full object to avoid GlobalID dependency initially
- Supports both ID and GlobalID for flexibility
- `limits_concurrency` gated behind `respond_to?` for non-SolidQueue adapters
- Delegates to existing `FlowExecutor` to reuse battle-tested execution logic

---

### Task 2: Create ActiveJob Runtime Class

**File**: `lib/active_data_flow/runtime/active_job.rb`

```ruby
# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    class ActiveJob < Base
      attr_reader :queue, :priority

      def initialize(
        queue: :active_data_flow,
        priority: nil,
        batch_size: 100,
        enabled: true,
        interval: 3600,
        **options
      )
        super(batch_size: batch_size, enabled: enabled, interval: interval, **options)
        @queue = queue
        @priority = priority
      end

      # Execute immediately via ActiveJob
      def execute(data_flow)
        return unless enabled?

        job = ActiveDataFlow::DataFlowJob
          .set(queue: queue, priority: priority)
          .perform_later(data_flow.id)

        Rails.logger.info "[ActiveJob Runtime] Enqueued job #{job.job_id} for flow #{data_flow.name}"
        job
      end

      # Schedule for later execution
      def execute_at(data_flow, run_at)
        return unless enabled?

        job = ActiveDataFlow::DataFlowJob
          .set(queue: queue, priority: priority, wait_until: run_at)
          .perform_later(data_flow.id)

        Rails.logger.info "[ActiveJob Runtime] Scheduled job #{job.job_id} for flow #{data_flow.name} at #{run_at}"
        job
      end

      # Schedule next run based on interval
      def schedule_next(data_flow, from_time: Time.current)
        return unless enabled?

        next_run = from_time + interval.seconds
        execute_at(data_flow, next_run)
      end

      def as_json(*_args)
        super.merge(
          'queue' => queue.to_s,
          'priority' => priority
        )
      end

      def self.from_json(data)
        data = data.symbolize_keys
        data.delete(:class_name)
        data[:queue] = data[:queue]&.to_sym || :active_data_flow
        new(**data)
      end
    end
  end
end
```

**Rationale**:
- Extends `Runtime::Base` to maintain interface compatibility
- Adds `queue` and `priority` for ActiveJob configuration
- `execute` for immediate, `execute_at` for scheduled, `schedule_next` for recurring
- Serializes to JSON like other runtimes

---

### Task 3: Add GlobalID Support to DataFlow

**File**: `app/models/active_data_flow/active_record/data_flow.rb` (modification)

Add to the class:

```ruby
include GlobalID::Identification

# GlobalID uses this to locate records
def self.find(id)
  super
rescue ActiveRecord::RecordNotFound
  nil  # Return nil instead of raising for job deserialization
end
```

**Note**: GlobalID is included in Rails by default, no gem addition needed.

---

### Task 4: Create Runtime Adapter Configuration

**File**: `lib/active_data_flow/configuration.rb` (modification)

Add to Configuration class:

```ruby
attr_accessor :runtime_adapter

SUPPORTED_RUNTIMES = [:heartbeat, :active_job].freeze

def initialize
  # ... existing code ...
  @runtime_adapter = :heartbeat  # Default to existing behavior
end

def validate_runtime_adapter
  if SUPPORTED_RUNTIMES.include?(runtime_adapter)
    Success(runtime_adapter)
  else
    Failure[:configuration_error, {
      message: "Unsupported runtime adapter: #{runtime_adapter}",
      supported: SUPPORTED_RUNTIMES,
      provided: runtime_adapter
    }]
  end
end

def active_job_runtime?
  runtime_adapter == :active_job
end
```

---

### Task 5: Integrate with Engine Initialization

**File**: `lib/active_data_flow/engine.rb` (modification)

Add ActiveJob runtime loading:

```ruby
initializer "active_data_flow.active_job" do
  ActiveSupport.on_load(:active_job) do
    require "active_data_flow/runtime/active_job"
  end
end
```

---

### Task 6: Create Generator for Installation

**File**: `lib/generators/active_data_flow/active_job/active_job_generator.rb`

```ruby
# frozen_string_literal: true

module ActiveDataFlow
  module Generators
    class ActiveJobGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_application_job_if_missing
        unless File.exist?(Rails.root.join("app/jobs/application_job.rb"))
          template "application_job.rb", "app/jobs/application_job.rb"
        end
      end

      def update_configuration
        inject_into_file "config/initializers/active_data_flow.rb",
          after: "ActiveDataFlow.configure do |config|\n" do
          "  config.runtime_adapter = :active_job\n"
        end
      end

      def show_instructions
        say ""
        say "ActiveJob runtime installed!", :green
        say ""
        say "Next steps:"
        say "  1. Configure your queue adapter in config/application.rb"
        say "  2. For SolidQueue: rails solid_queue:install"
        say "  3. Start processing: bin/jobs"
        say ""
      end
    end
  end
end
```

---

### Task 7: Add Rake Task for Manual Triggering

**File**: `lib/tasks/active_data_flow.rake` (add task)

```ruby
namespace :active_data_flow do
  desc "Enqueue all active flows for immediate execution"
  task enqueue_all: :environment do
    count = 0
    ActiveDataFlow::DataFlow.active.find_each do |flow|
      if flow.enabled?
        ActiveDataFlow::DataFlowJob.perform_later(flow.id)
        count += 1
      end
    end
    puts "Enqueued #{count} data flows"
  end

  desc "Enqueue a specific flow by name"
  task :enqueue, [:name] => :environment do |_, args|
    flow = ActiveDataFlow::DataFlow.find_by!(name: args[:name])
    if flow.enabled?
      job = ActiveDataFlow::DataFlowJob.perform_later(flow.id)
      puts "Enqueued flow '#{flow.name}' as job #{job.job_id}"
    else
      puts "Flow '#{flow.name}' is disabled"
    end
  end
end
```

---

## File Summary

| Action | File | LOC |
|--------|------|-----|
| Create | `app/jobs/active_data_flow/data_flow_job.rb` | ~50 |
| Create | `lib/active_data_flow/runtime/active_job.rb` | ~70 |
| Modify | `app/models/active_data_flow/active_record/data_flow.rb` | +5 |
| Modify | `lib/active_data_flow/configuration.rb` | +20 |
| Modify | `lib/active_data_flow/engine.rb` | +5 |
| Create | `lib/generators/active_data_flow/active_job/active_job_generator.rb` | ~35 |
| Modify | `lib/tasks/active_data_flow.rake` | +25 |

**Total**: ~210 lines of new code

---

## Testing Strategy

### Unit Tests

```ruby
# spec/jobs/active_data_flow/data_flow_job_spec.rb
RSpec.describe ActiveDataFlow::DataFlowJob do
  let(:data_flow) { create(:data_flow, :active) }

  it "executes the flow" do
    expect(ActiveDataFlow::Runtime::FlowExecutor)
      .to receive(:execute).and_return(Success(:completed))

    described_class.perform_now(data_flow.id)
  end

  it "handles missing flows gracefully" do
    expect { described_class.perform_now(999999) }.not_to raise_error
  end

  it "skips disabled flows" do
    data_flow.update!(status: 'inactive')

    expect(ActiveDataFlow::Runtime::FlowExecutor).not_to receive(:execute)
    described_class.perform_now(data_flow.id)
  end
end
```

### Integration Tests

```ruby
# spec/runtime/active_job_spec.rb
RSpec.describe ActiveDataFlow::Runtime::ActiveJob do
  let(:runtime) { described_class.new(queue: :test, interval: 60) }
  let(:data_flow) { create(:data_flow) }

  describe "#execute" do
    it "enqueues a job" do
      expect {
        runtime.execute(data_flow)
      }.to have_enqueued_job(ActiveDataFlow::DataFlowJob)
        .with(data_flow.id)
        .on_queue(:test)
    end
  end

  describe "#schedule_next" do
    it "schedules job for future execution" do
      freeze_time do
        expect {
          runtime.schedule_next(data_flow)
        }.to have_enqueued_job(ActiveDataFlow::DataFlowJob)
          .at(60.seconds.from_now)
      end
    end
  end

  describe "serialization" do
    it "round-trips through JSON" do
      json = runtime.as_json
      restored = described_class.from_json(json)

      expect(restored.queue).to eq(:test)
      expect(restored.interval).to eq(60)
    end
  end
end
```

---

## Migration Path

### For Existing Heartbeat Users

1. Install ActiveJob runtime:
   ```bash
   rails generate active_data_flow:active_job
   ```

2. Update existing flows to use ActiveJob runtime:
   ```ruby
   # One-time migration
   ActiveDataFlow::DataFlow.find_each do |flow|
     old_runtime = flow.parsed_runtime
     new_runtime = ActiveDataFlow::Runtime::ActiveJob.new(
       interval: old_runtime['interval'] || 3600,
       batch_size: old_runtime['batch_size'] || 100,
       enabled: old_runtime['enabled'] != false
     )
     flow.update!(runtime: new_runtime.as_json)
   end
   ```

3. Cancel pending Heartbeat runs:
   ```ruby
   ActiveDataFlow::DataFlowRun.pending.update_all(status: 'cancelled')
   ```

4. Enqueue all active flows:
   ```bash
   rails active_data_flow:enqueue_all
   ```

---

## Acceptance Criteria

- [ ] `DataFlowJob` executes flows via existing `FlowExecutor`
- [ ] `Runtime::ActiveJob` can be serialized/deserialized
- [ ] Flows with `Runtime::ActiveJob` execute when job runs
- [ ] `limits_concurrency` prevents duplicate flow execution (SolidQueue only)
- [ ] Generator updates configuration correctly
- [ ] Rake tasks work for manual triggering
- [ ] All existing tests pass
- [ ] New tests cover ActiveJob runtime

---

## Dependencies

- Rails >= 6.1 (for GlobalID enhancements)
- No new gems required (ActiveJob ships with Rails)
- Optional: SolidQueue for `limits_concurrency` support

---

## Next Phase Preview

Phase 2 will add SolidQueue recurring jobs support:
- Generate `config/recurring.yml` from flow schedules
- Add DSL for schedule definition in flow classes
- Create rake task for schedule synchronization

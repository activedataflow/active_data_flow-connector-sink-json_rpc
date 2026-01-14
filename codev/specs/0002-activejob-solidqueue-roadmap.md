# Specification 0002: ActiveJob & SolidQueue Integration Roadmap

## Overview

This roadmap prioritizes deep integration with Rails ActiveJob and SolidQueue (Rails 8+ default queue adapter). The goal is to make Active Data Flow a first-class citizen in the Rails job ecosystem rather than maintaining parallel scheduling infrastructure.

## Strategic Vision

**Current State**: Active Data Flow has custom runtimes (Heartbeat, Redcord) that duplicate functionality Rails provides natively through ActiveJob/SolidQueue.

**Target State**: Active Data Flow becomes a "flow definition layer" on top of ActiveJob, leveraging SolidQueue's battle-tested scheduling, concurrency controls, and recurring job support.

---

## Phase 1: ActiveJob Runtime Foundation

**Goal**: Create an ActiveJob-native runtime that replaces Heartbeat scheduling.

### 1.1 Core ActiveJob Runtime

Create `ActiveDataFlow::Runtime::ActiveJob` that:
- Wraps flow execution in an `ApplicationJob` subclass
- Uses GlobalID to serialize DataFlow references
- Integrates with `ActiveJob::Continuable` for cursor-based batch processing
- Respects ActiveJob callbacks (`before_perform`, `after_perform`)

```ruby
# Target API
runtime = ActiveDataFlow::Runtime::ActiveJob.new(
  queue: :data_flows,
  priority: 10,
  batch_size: 100
)
```

### 1.2 DataFlowJob Implementation

```ruby
class ActiveDataFlow::DataFlowJob < ApplicationJob
  include ActiveJob::Continuable  # Rails 8+ cursor support

  queue_as :data_flows
  limits_concurrency key: ->(flow) { "data_flow:#{flow.name}" }

  def perform(data_flow)
    # Leverage continuation cursors for batch processing
    step :process_batch do |cursor|
      data_flow.run_batch(cursor: cursor)
    end
  end
end
```

### 1.3 GlobalID Integration

- Add `include GlobalID::Identification` to DataFlow model
- Enable passing DataFlow objects directly to jobs
- Handle `ActiveJob::DeserializationError` for deleted flows

---

## Phase 2: SolidQueue Recurring Jobs

**Goal**: Replace Heartbeat scheduler with SolidQueue's native recurring job support.

### 2.1 Recurring Job Generator

Create generator for `config/recurring.yml` entries:

```yaml
# config/recurring.yml (auto-generated)
data_flow_user_sync:
  class: ActiveDataFlow::DataFlowJob
  args:
    - gid://app/ActiveDataFlow::DataFlow/1
  schedule: every 5 minutes

data_flow_order_export:
  class: ActiveDataFlow::DataFlowJob
  args:
    - gid://app/ActiveDataFlow::DataFlow/2
  schedule: at 2am every day
```

### 2.2 DSL for Schedule Definition

```ruby
# app/data_flows/user_sync_flow.rb
class UserSyncFlow < ActiveDataFlow::Base
  source :users, scope: :active
  sink :user_backups

  schedule :every, 5.minutes    # Generates recurring.yml entry
  # OR
  schedule :cron, "0 2 * * *"   # Daily at 2am
end
```

### 2.3 Schedule Synchronization

- Rake task: `rails active_data_flow:sync_schedules`
- Reads all registered DataFlows
- Generates/updates `config/recurring.yml`
- Integrates with SolidQueue's scheduler process

---

## Phase 3: Concurrency & Flow Coordination

**Goal**: Leverage SolidQueue's concurrency controls for flow execution safety.

### 3.1 Concurrency Limits

```ruby
class ActiveDataFlow::DataFlowJob < ApplicationJob
  # Prevent same flow from running concurrently
  limits_concurrency key: ->(flow) { "flow:#{flow.name}" }

  # OR limit across flow groups
  limits_concurrency key: ->(flow) { "flow_group:#{flow.group}" },
                     to: 3  # Max 3 concurrent flows per group
end
```

### 3.2 Flow Dependencies

Support flow chaining via ActiveJob callbacks:

```ruby
class OrderExportFlow < ActiveDataFlow::Base
  after_complete :trigger_downstream

  def trigger_downstream
    NotificationFlow.enqueue_now
  end
end
```

### 3.3 Bulk Enqueuing

Use `perform_all_later` for batch flow scheduling:

```ruby
# Schedule multiple flows efficiently
ActiveDataFlow::DataFlowJob.perform_all_later(
  DataFlow.where(status: :active).map { |f| [f] }
)
```

---

## Phase 4: Job Continuations for Batch Processing

**Goal**: Replace cursor management with ActiveJob::Continuable.

### 4.1 Continuation-Based Execution

```ruby
class ActiveDataFlow::DataFlowJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(data_flow)
    step :fetch_batch, cursor: nil do |cursor|
      records = data_flow.source.fetch(after: cursor, limit: batch_size)
      { records: records, next_cursor: records.last&.id }
    end

    step :process_records do |batch|
      batch[:records].each { |r| data_flow.sink.write(r) }
    end
  end
end
```

### 4.2 Progress Tracking

- Map continuation state to DataFlowRun records
- Surface progress in web UI via job inspection
- Enable resume-from-failure without re-processing

---

## Phase 5: Error Handling & Observability

**Goal**: Integrate with ActiveJob's error handling and Rails instrumentation.

### 5.1 Declarative Retry Policies

```ruby
class ActiveDataFlow::DataFlowJob < ApplicationJob
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 10
  discard_on ActiveJob::DeserializationError  # Flow was deleted

  after_discard do |job, error|
    job.arguments.first.update!(status: :failed, last_error: error.message)
  end
end
```

### 5.2 Instrumentation

Subscribe to ActiveSupport::Notifications:

```ruby
ActiveSupport::Notifications.subscribe("perform.active_job") do |event|
  if event.payload[:job].is_a?(ActiveDataFlow::DataFlowJob)
    ActiveDataFlow::Metrics.record(event)
  end
end
```

### 5.3 SolidQueue Dashboard Integration

- Expose flow status via SolidQueue's job inspection
- Link DataFlowRun to SolidQueue::Job records
- Surface queue depth and processing rates

---

## Phase 6: Migration & Compatibility

**Goal**: Smooth upgrade path from Heartbeat/Redcord runtimes.

### 6.1 Runtime Adapter Pattern

```ruby
ActiveDataFlow.configure do |config|
  config.runtime_adapter = :active_job  # New default
  # OR
  config.runtime_adapter = :heartbeat   # Legacy support
  config.runtime_adapter = :redcord     # Event-driven
end
```

### 6.2 Migration Generator

```bash
rails generate active_data_flow:migrate_to_activejob
```

- Converts existing Heartbeat schedules to recurring.yml
- Creates SolidQueue migration if needed
- Updates configuration

### 6.3 Deprecation Timeline

| Version | Status |
|---------|--------|
| 1.0 | ActiveJob runtime available, Heartbeat default |
| 1.1 | ActiveJob default, Heartbeat deprecated warning |
| 2.0 | Heartbeat removed, ActiveJob only |

---

## Implementation Priority

### Must Have (P0)
1. Phase 1: ActiveJob Runtime Foundation
2. Phase 2: SolidQueue Recurring Jobs
3. Phase 6.1-6.2: Migration path

### Should Have (P1)
4. Phase 3: Concurrency Controls
5. Phase 5: Error Handling

### Nice to Have (P2)
6. Phase 4: Job Continuations
7. Phase 5.3: Dashboard Integration

---

## Dependencies

- Rails >= 7.1 (for SolidQueue support)
- Rails >= 8.0 (for ActiveJob::Continuable)
- SolidQueue >= 1.0
- GlobalID (ships with Rails)

---

## Success Metrics

1. **Zero custom scheduling code**: All timing handled by SolidQueue
2. **Native Rails tooling**: Flows visible in standard Rails job dashboards
3. **Reduced gem surface**: Remove Heartbeat runtime (~400 LOC)
4. **Improved reliability**: Leverage SolidQueue's proven job persistence

---

## Open Questions

1. Should Redcord runtime remain for event-driven use cases, or can SolidQueue handle this via immediate enqueuing?
2. How to handle Rails < 8.0 without ActiveJob::Continuable? (Backport or feature-flag?)
3. Should we support other queue adapters (Sidekiq, GoodJob) or focus exclusively on SolidQueue?

---

## References

- [ActiveJob Basics Guide](https://guides.rubyonrails.org/active_job_basics.html)
- [SolidQueue README](https://github.com/rails/solid_queue)
- [GlobalID Documentation](https://github.com/rails/globalid)
- [ActiveJob::Continuable (Rails 8)](https://api.rubyonrails.org/classes/ActiveJob/Continuable.html)

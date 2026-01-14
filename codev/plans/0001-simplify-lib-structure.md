# Plan 0001: Simplify lib/active_data_flow Structure

## Phase 1: Consolidate Duplicate Classes

### 1.1 Merge FlowReschedule Classes
**Files affected:**
- `runtime/heartbeat/flow_reschedule.rb` (23 lines)
- `runtime/redcord/flow_reschedule.rb` (23 lines)

**Action:** Create single `Runtime::FlowReschedule` in `runtime/flow_reschedule.rb`
- Both are identical - single implementation works for both backends
- Update both Heartbeat and Redcord modules to use shared class

### 1.2 Consolidate FlowExecutor Classes
**Files affected:**
- `runtime/heartbeat/flow_run_executor.rb` (70 lines)
- `runtime/redcord/flow_executor.rb` (48 lines)

**Action:** Create `Runtime::FlowExecutor` base class
- Extract common pattern: mark_started -> run -> mark_completed/failed
- Use Result monads consistently (Heartbeat's pattern)
- Subclasses only provide backend-specific model access

### 1.3 Extract Configuration Base Class
**Files affected:**
- `configuration.rb` (67 lines)
- `connector/json_rpc/configuration.rb` (18 lines)
- `runtime/heartbeat/configuration.rb` (23 lines)
- `runtime/redcord/configuration.rb` (23 lines)

**Action:** Create `ConfigurationBase` module
```ruby
module ConfigurationBase
  extend ActiveSupport::Concern

  class_methods do
    def configuration
      @configuration ||= self::Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = self::Configuration.new
    end
  end
end
```
- Each module includes `ConfigurationBase` and defines only its `Configuration` class

---

## Phase 2: Break Apart Large Classes

### 2.1 Split StorageBackendLoader (188 lines -> 3 files)
**Current file:** `storage_backend_loader.rb`

**Action:** Extract into:
- `storage_backend/loader.rb` - Main orchestrator (choose which loader)
- `storage_backend/active_record_loader.rb` - AR-specific setup
- `storage_backend/redcord_loader.rb` - Redcord/Redis setup

Each loader:
- Validates its dependencies
- Configures autoload paths
- Initializes connections

### 2.2 Extract Buffer Management from JsonRpcSink (179 lines)
**Current file:** `connector/sink/json_rpc.rb`

**Action:** Extract `Connector::Sink::Buffer` class
- Handles mutex, buffer array, flush logic
- JsonRpcSink delegates buffering to this class
- Reduces JsonRpcSink to ~100 lines

### 2.3 Simplify JsonRpcSource Server Lifecycle (137 lines)
**Current file:** `connector/source/json_rpc.rb`

**Action:**
- Extract `Connector::JsonRpc::ServerLifecycle` module
- Proper synchronization for server startup (remove `sleep 0.5`)
- Use ConditionVariable for startup coordination
- Reduces source to data-fetching logic only

---

## Phase 3: Remove Dead Weight

### 3.1 Remove Empty Namespace Modules
**Files to delete:**
- `connector.rb` (3 lines - just `module Connector; end`)
- `runtime.rb` (3 lines - just `module Runtime; end`)

**Action:** Ruby autoloading handles namespaces automatically

### 3.2 Clean Up Message Module
**Current file:** `message.rb` (8 lines)

**Action:** Move requires into main `active_data_flow.rb` or use autoloading

### 3.3 Evaluate Collision Detection
**Files affected:**
- `connector/sink/collision.rb` (34 lines)
- Collision logic in `connector/sink/base.rb`

**Action:** Currently collision detector always returns `NO_PREDICTION`
- If not actively used, remove or simplify to stub
- If needed, document clearly and add tests

---

## Phase 4: Standardize Patterns

### 4.1 Consistent Error Handling
**Current state:** Mix of Result monads and exceptions

**Action:** Standardize on Result monads for:
- All FlowExecutor operations
- All Sink/Source operations
- Keep exceptions only at boundaries (HTTP controllers, CLI)

Update:
- `runtime/redcord/flow_executor.rb` - Use Result instead of exceptions
- Document error handling convention in README

### 4.2 Consolidate Module Loading Patterns
**Files affected:**
- `runtime/heartbeat/heartbeat.rb` (42 lines)
- `runtime/redcord/redcord.rb` (54 lines)

**Action:** Both have identical patterns for:
- Loading models directory
- Loading controllers directory
- Configuration setup

Extract `Runtime::ModuleLoader` mixin to share this logic.

### 4.3 Improve Flow Discovery
**File:** `data_flows_folder.rb` (122 lines)

**Action:**
- Replace `Object.const_get` with safer `constantize` with error handling
- Validate flow class responds to `register` before calling
- Add clear error messages for malformed flow files

---

## Implementation Order

```
Phase 1 (Lowest Risk - Pure Consolidation)
├── 1.1 Merge FlowReschedule
├── 1.2 Consolidate FlowExecutor
└── 1.3 Extract ConfigurationBase

Phase 2 (Medium Risk - Refactoring)
├── 2.1 Split StorageBackendLoader
├── 2.2 Extract Buffer from JsonRpcSink
└── 2.3 Simplify JsonRpcSource

Phase 3 (Low Risk - Cleanup)
├── 3.1 Remove empty modules
├── 3.2 Clean Message module
└── 3.3 Evaluate Collision

Phase 4 (Medium Risk - Standardization)
├── 4.1 Consistent error handling
├── 4.2 Consolidate module loading
└── 4.3 Improve flow discovery
```

---

## Expected Results

| Metric | Before | After |
|--------|--------|-------|
| Total files | 39 | ~28 |
| Total LOC | ~2000 | ~1500 |
| Duplicate classes | 4 | 0 |
| Max file size | 188 LOC | <100 LOC |
| Empty namespace files | 3 | 0 |

---

## File Changes Summary

### New Files
- `lib/active_data_flow/configuration_base.rb`
- `lib/active_data_flow/runtime/flow_reschedule.rb`
- `lib/active_data_flow/runtime/flow_executor.rb`
- `lib/active_data_flow/storage_backend/loader.rb`
- `lib/active_data_flow/storage_backend/active_record_loader.rb`
- `lib/active_data_flow/storage_backend/redcord_loader.rb`
- `lib/active_data_flow/connector/sink/buffer.rb`
- `lib/active_data_flow/connector/json_rpc/server_lifecycle.rb`
- `lib/active_data_flow/runtime/module_loader.rb`

### Files to Delete
- `lib/active_data_flow/connector.rb`
- `lib/active_data_flow/runtime.rb`
- `lib/active_data_flow/message.rb`
- `lib/active_data_flow/storage_backend_loader.rb` (replaced)
- `lib/active_data_flow/runtime/heartbeat/flow_reschedule.rb` (merged)
- `lib/active_data_flow/runtime/redcord/flow_reschedule.rb` (merged)

### Files Modified
- Most existing files will have minor updates to use new shared classes

---

## Testing Strategy

1. **Before starting:** Run full test suite, record baseline
2. **After each phase:** Run tests, ensure no regressions
3. **Phase 1 specific:** Test both Heartbeat and Redcord backends
4. **Phase 2 specific:** Test JSON-RPC communication, storage loading
5. **Final:** Integration tests with example Rails app in submodules

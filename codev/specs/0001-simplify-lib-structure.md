# Spec 0001: Simplify lib/active_data_flow Structure

## Overview

Refactor `lib/active_data_flow` to reduce complexity, eliminate duplication, and improve maintainability while preserving all functionality.

## Current State

- **39 files, ~2000 lines** of Ruby code
- **4 duplicate Configuration classes** with identical patterns
- **2 duplicate FlowReschedule classes** (Heartbeat/Redcord - identical code)
- **2 similar FlowExecutor classes** with inconsistent error handling
- **3 large complex classes** (StorageBackendLoader 188 LOC, JsonRpcSink 179 LOC, JsonRpcSource 137 LOC)
- **Inconsistent error handling** (mix of Result monads and exceptions)
- **Empty namespace modules** providing no value

## Goals

1. **Eliminate duplication** - DRY up repeated patterns
2. **Reduce complexity** - Break apart large monolithic classes
3. **Improve consistency** - Standardize error handling approach
4. **Simplify structure** - Remove unnecessary abstractions

## Non-Goals

- Changing public API behavior
- Adding new features
- Modifying storage backend functionality
- Changing the JSON-RPC protocol

## Success Criteria

- Fewer files (target: ~25-30 vs current 39)
- Fewer total lines of code (target: <1600 vs current ~2000)
- No duplicate classes
- Consistent error handling pattern throughout
- All existing tests pass
- No breaking changes to public API

## Risks

- Regression in runtime behavior if consolidation done incorrectly
- Breaking host applications that depend on internal classes
- JSON-RPC communication issues if refactoring changes timing

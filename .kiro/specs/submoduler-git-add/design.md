# Design Document: Submoduler Git-Add Command

## Overview

The `git-add` command stages changes across multiple submodules and the parent repository in a single operation. It supports pattern matching, interactive mode, patch mode, and various git-add options.

## Architecture

```
SubmodulerCLI → GitAddCommand → AddExecutor → StatusFormatter
                      ↓
                FileScanner → PatternMatcher
```

## Components

### GitAddCommand
- Orchestrates add operations across repositories
- Parses options: --all, --interactive, --patch, --dry-run, --update, --force
- Filters submodules based on --submodule flag
- Updates parent repository submodule references

### FileScanner
- Scans for modified/untracked files in each submodule
- Applies pattern matching for selective staging
- Returns list of files to stage per repository

### AddExecutor
- Executes `git add` commands in each submodule
- Supports interactive and patch modes
- Handles dry-run mode
- Captures and reports errors

### StatusFormatter
- Displays progress for each submodule
- Shows files being staged
- Provides summary statistics

## Data Models

```ruby
AddOperation = {
  submodule_name: String,
  path: String,
  files: Array<String>,
  pattern: String,
  options: Hash
}

AddResult = {
  success: Boolean,
  files_staged: Integer,
  message: String,
  error: String
}
```

## Command Flow

1. Parse command line options
2. Scan submodules for files matching criteria
3. For each submodule:
   - Execute git add with appropriate flags
   - Display progress
   - Handle errors
4. Update parent repository submodule references if needed
5. Display summary

## Testing Strategy

- Unit tests for FileScanner pattern matching
- Unit tests for AddExecutor command building
- Integration tests for full add flow
- Test interactive and patch modes
- Test error handling


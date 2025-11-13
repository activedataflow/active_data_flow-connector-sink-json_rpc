# Design Document: Submoduler Git-Commit Command

## Overview

The `git-commit` command commits staged changes across multiple submodules and the parent repository. It supports unified or individual commit messages, amend mode, signed commits, and various git-commit options.

## Architecture

```
SubmodulerCLI → GitCommitCommand → CommitExecutor → CommitFormatter
                       ↓
                MessageComposer → EditorLauncher
```

## Components

### GitCommitCommand
- Orchestrates commit operations across repositories
- Parses options: -m, --amend, --all, --gpg-sign, --interactive
- Filters submodules based on --submodule flag
- Manages commit sequencing

### MessageComposer
- Handles commit message creation
- Supports unified messages across all repos
- Supports per-submodule messages in interactive mode
- Launches editor for message composition

### CommitExecutor
- Executes `git commit` commands in each submodule
- Supports amend, all, allow-empty, gpg-sign options
- Runs commit hooks (pre-commit, commit-msg)
- Captures commit SHAs and results

### CommitFormatter
- Displays commit progress
- Shows commit SHAs and messages
- Provides summary statistics

## Data Models

```ruby
CommitOperation = {
  submodule_name: String,
  path: String,
  message: String,
  options: Hash
}

CommitResult = {
  success: Boolean,
  commit_sha: String,
  message: String,
  files_committed: Integer,
  error: String
}
```

## Command Flow

1. Parse command line options
2. Check for staged changes in each submodule
3. Compose commit message(s):
   - Use -m flag if provided
   - Launch editor if no message
   - Prompt per-submodule in interactive mode
4. For each submodule with staged changes:
   - Execute git commit
   - Run commit hooks
   - Capture commit SHA
   - Display result
5. Commit parent repository
6. Display summary

## Commit Hooks

- Execute pre-commit hooks for validation
- Execute commit-msg hooks for message validation
- Support --no-verify flag to skip hooks
- Report hook failures clearly

## Testing Strategy

- Unit tests for MessageComposer
- Unit tests for CommitExecutor command building
- Integration tests for full commit flow
- Test amend mode
- Test signed commits
- Test hook execution


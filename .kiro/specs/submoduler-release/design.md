# Design Document: Submoduler Release Management

## Overview

The release management feature orchestrates a complete release workflow across all submodules: version synchronization, committing changes, running tests, and pushing to remotes. It ensures a consistent and validated release process.

## Architecture

### Command Pattern
The `ReleaseCommand` orchestrates the workflow by delegating to existing commands:
- `VersionCommand` for version synchronization
- `GitAddCommand` for staging changes
- `GitCommitCommand` for committing
- `TestCommand` for running tests
- `PushCommand` for pushing changes

### Workflow Diagram

```
ReleaseCommand
 ├─> 1. Validate message required
 ├─> 2. VersionCommand (--sync)
 ├─> 3. GitAddCommand (--all)
 ├─> 4. GitCommitCommand (-m message)
 ├─> 5. TestCommand
 └─> 6. PushCommand (if tests pass)
```

## Components and Interfaces

### ReleaseCommand
**Responsibility:** Orchestrates the complete release workflow

**Interface:**
```ruby
class ReleaseCommand
  def initialize(repo_root, options = {})
  def execute
  private
  def validate_message
  def sync_versions
  def commit_changes
  def run_tests
  def push_changes
  def handle_failure(step, error)
end
```

**Workflow Steps:**
1. **Validate Message**: Ensure -m/--message is provided
2. **Sync Versions**: Run version command with --sync
3. **Commit Changes**: Stage and commit all changes
4. **Run Tests**: Execute test suite for all submodules
5. **Push Changes**: Push submodules and parent if tests pass

## Data Models

### Release Result Structure
```ruby
{
  success: true,
  steps_completed: [:validate, :sync, :commit, :test, :push],
  failed_step: nil,
  error_message: nil
}
```

## Error Handling

### Missing Message
- Display error: "Error: Release message is required. Use -m or --message option"
- Exit with code 2
- Don't proceed with any steps

### Version Sync Fails
- Display error from version command
- Exit with code 1
- Don't proceed to commit

### Commit Fails
- Display error from commit command
- Exit with code 1
- Don't proceed to test

### Tests Fail
- Display error from test command
- Display message: "Tests failed. Commits created but not pushed."
- Display rollback instructions
- Exit with code 1
- Don't push changes

### Push Fails
- Display error from push command
- Exit with code 1
- Changes are committed but not pushed

## Dry Run Mode

When `--dry-run` is provided:
1. Show message that would be used
2. Show version sync preview (from version --sync --dry-run)
3. Show files that would be committed
4. Show message: "Would run tests"
5. Show message: "Would push changes"
6. Exit with code 0

## Selective Submodule Release

When `--submodule <name>` is provided:
- Pass filter to version command
- Pass filter to commit command
- Pass filter to test command
- Pass filter to push command
- Still update parent repository

## Implementation Notes

### Command Delegation
Reuse existing commands rather than duplicating logic:
```ruby
version_cmd = VersionCommand.new(@repo_root, sync: true, dry_run: @options[:dry_run])
exit_code = version_cmd.execute
```

### Output Management
- Show progress for each step
- Use consistent formatting
- Show command output inline
- Summarize at the end

### Rollback Guidance
When tests fail after commits:
```
Tests failed. Commits created but not pushed.

To rollback commits:
  git reset --soft HEAD~1  # In each submodule
  git reset --soft HEAD~1  # In parent repository

Or fix the issues and run:
  submoduler.rb test       # Verify tests pass
  submoduler.rb push       # Push the commits
```

## CLI Integration

### New Command
Add to CLI.rb:
```ruby
when 'release'
  ReleaseCommand.new(@repo_root, options).execute
```

### Required Options
- `-m, --message <msg>`: Release message (required)

### Optional Options
- `--dry-run`: Preview without executing
- `--submodule <name>`: Release specific submodules

### Help Text Addition
```
release                 Release submodules with version sync, test, and push

Release Options:
  -m, --message <msg>     Release message (required)
  --dry-run               Preview release workflow
  --submodule <name>      Release specific submodule(s)
```

## Dependencies

### Existing Components
- `VersionCommand`: Synchronize versions
- `GitAddCommand`: Stage changes
- `GitCommitCommand`: Commit changes
- `TestCommand`: Run tests
- `PushCommand`: Push changes

### New Files
- `lib/submoduler/release_command.rb`

### External Dependencies
None - orchestrates existing commands

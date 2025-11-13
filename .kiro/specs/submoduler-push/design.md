# Design Document: Submoduler Push Command

## Overview

The `push` command automates pushing changes from modified submodules to their remote repositories, followed by pushing the parent repository. This ensures submodule commits are available remotely before the parent repository references them, preventing checkout failures for other developers.

The design uses a sequential push strategy with comprehensive error handling and multiple operation modes (dry-run, force, selective).

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    SubmodulerCLI                        │
│  - Parses command line arguments                        │
│  - Routes to PushCommand                                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   PushCommand                           │
│  - Orchestrates push operations                         │
│  - Manages push sequence and error handling             │
└────────┬────────────────────────────────────────────────┘
         │
         ├──────────────┬──────────────┬─────────────────┐
         ▼              ▼              ▼                 ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│SubmoduleRepo │ │PushValidator │ │PushExecutor  │ │PushFormatter │
│Scanner       │ │              │ │              │ │              │
│              │ │              │ │              │ │              │
│- Detects     │ │- Checks      │ │- Executes    │ │- Formats     │
│  modified    │ │  remote      │ │  git push    │ │  output      │
│  submodules  │ │  tracking    │ │- Handles     │ │- Progress    │
│- Counts      │ │- Validates   │ │  errors      │ │- Summaries   │
│  unpushed    │ │  auth        │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

## Components and Interfaces

### 1. PushCommand

**Responsibility**: Orchestrate the push operation across submodules and parent

**Interface**:
```ruby
class PushCommand
  def initialize(repo_root, options = {})
    @repo_root = repo_root
    @options = options
    @dry_run = options[:dry_run]
    @force = options[:force]
    @remote = options[:remote] || 'origin'
    @submodules = options[:submodules]
  end
  
  def execute
    # Returns exit code (0 for success, 1 for failures)
  end
  
  private
  
  def scan_submodules
    # Identify submodules with unpushed commits
  end
  
  def push_submodules(submodules)
    # Push each submodule sequentially
  end
  
  def push_parent
    # Push parent repository
  end
end
```

**Behavior**:
- Scan for modified submodules with unpushed commits
- Validate remote tracking and authentication
- Push submodules sequentially
- Push parent repository after all submodules succeed
- Handle errors and provide detailed feedback

### 2. SubmoduleRepoScanner

**Responsibility**: Detect submodules with unpushed commits

**Interface**:
```ruby
class SubmoduleRepoScanner
  def initialize(repo_root, gitmodules_parser)
    @repo_root = repo_root
    @parser = gitmodules_parser
  end
  
  def scan
    # Returns array of ModifiedSubmodule objects
  end
  
  private
  
  def check_unpushed_commits(submodule_path)
    # Count commits ahead of remote
  end
  
  def check_uncommitted_changes(submodule_path)
    # Detect uncommitted changes
  end
end

class ModifiedSubmodule
  attr_reader :name, :path, :unpushed_count, :has_uncommitted
  
  def initialize(name:, path:, unpushed_count:, has_uncommitted:)
    @name = name
    @path = path
    @unpushed_count = unpushed_count
    @has_uncommitted = has_uncommitted
  end
end
```

**Behavior**:
- Parse `.gitmodules` to get submodule list
- For each submodule, run `git rev-list @{u}..HEAD --count`
- Detect uncommitted changes with `git status --porcelain`
- Return list of submodules with unpushed commits

### 3. PushValidator

**Responsibility**: Validate push preconditions

**Interface**:
```ruby
class PushValidator
  def initialize(repo_root)
    @repo_root = repo_root
  end
  
  def validate_submodule(submodule)
    # Returns ValidationResult
  end
  
  private
  
  def check_remote_tracking(path)
    # Verify branch has remote tracking
  end
  
  def check_remote_exists(path, remote)
    # Verify remote is configured
  end
end
```

**Behavior**:
- Check if branch has remote tracking configured
- Verify remote exists in git config
- Detect authentication issues before pushing
- Return validation results with actionable messages

### 4. PushExecutor

**Responsibility**: Execute git push operations

**Interface**:
```ruby
class PushExecutor
  def initialize(dry_run: false, force: false, remote: 'origin')
    @dry_run = dry_run
    @force = force
    @remote = remote
  end
  
  def push(path, branch)
    # Returns PushResult
  end
  
  private
  
  def build_push_command(branch)
    # Construct git push command
  end
  
  def execute_push(path, command)
    # Run git push and capture output
  end
end

class PushResult
  attr_reader :success, :message, :error
  
  def initialize(success:, message: nil, error: nil)
    @success = success
    @message = message
    @error = error
  end
  
  def success?
    @success
  end
end
```

**Behavior**:
- Build git push command with appropriate flags
- Execute push in submodule directory
- Capture stdout and stderr
- Parse git output for errors
- Return structured result

### 5. PushFormatter

**Responsibility**: Format push operation output

**Interface**:
```ruby
class PushFormatter
  def initialize(results)
    @results = results
  end
  
  def format
    # Returns formatted string
  end
  
  private
  
  def format_header(submodule_count)
    # Display operation header
  end
  
  def format_submodule_push(submodule, result)
    # Format individual push result
  end
  
  def format_summary(successful, failed)
    # Display final summary
  end
end
```

**Behavior**:
- Display header with operation mode (dry-run, force, etc.)
- Show progress for each submodule push
- Use colors for success/failure indicators
- Display final summary with counts

## Data Models

### ModifiedSubmodule
```ruby
{
  name: "core_gem/core",
  path: "submodules/core/core",
  unpushed_count: 3,
  has_uncommitted: false,
  current_branch: "main",
  remote_branch: "origin/main"
}
```

### PushResult
```ruby
{
  success: true,
  message: "Pushed 3 commits to origin/main",
  error: nil,
  commits_pushed: 3
}
```

### PushOperation
```ruby
{
  submodule_name: "core_gem/core",
  path: "submodules/core/core",
  remote: "origin",
  branch: "main",
  dry_run: false,
  force: false
}
```

## Push Sequence

### Normal Push Flow
1. Parse `.gitmodules` to get submodule list
2. Scan each submodule for unpushed commits
3. Filter submodules based on `--submodule` flag if provided
4. Validate each submodule (remote tracking, remote exists)
5. For each submodule with unpushed commits:
   - Display progress message
   - Execute `git push <remote> <branch>`
   - Check result and handle errors
   - If error, stop and report failure
6. After all submodules succeed, push parent repository
7. Display final summary

### Dry Run Flow
1-4. Same as normal flow
5. For each submodule with unpushed commits:
   - Display what would be pushed
   - Show commit count and branch
   - Skip actual push execution
6. Display what would be pushed for parent
7. Display summary of dry run

## Error Handling

### Push Failures
- **Authentication failure**: Detect "Permission denied" or "Authentication failed" in git output
- **Remote rejection**: Detect "rejected" or "non-fast-forward" in git output
- **Network errors**: Detect "Could not resolve host" or connection errors
- **No remote tracking**: Detect when branch has no upstream configured

### Error Messages
```
Error pushing submodule 'core_gem/core':
  Authentication failed for 'https://github.com/user/repo.git'
  
  Suggestions:
  - Check your SSH keys: ssh -T git@github.com
  - Verify your credentials are configured
  - Ensure you have push access to the repository

Exit Code: 1
```

### Partial Push Handling
When a submodule push fails:
1. Display error message with submodule name
2. List which submodules were successfully pushed
3. Do NOT push parent repository
4. Exit with code 1
5. User can fix issue and retry

## Command Line Options

### Flags
- `--dry-run`: Preview without pushing
- `--force`: Force push (requires confirmation)
- `--remote <name>`: Specify remote (default: origin)
- `--submodule <name>`: Push specific submodule(s)
- `--verbose`: Show detailed output
- `--no-parent`: Skip parent repository push

### Examples
```bash
# Push all modified submodules and parent
submoduler.rb push

# Dry run to preview
submoduler.rb push --dry-run

# Push specific submodules
submoduler.rb push --submodule core_gem/core --submodule runtime_gems/rails_heartbeat_app

# Force push to all
submoduler.rb push --force

# Push to different remote
submoduler.rb push --remote upstream
```

## Testing Strategy

### Unit Tests
1. **SubmoduleRepoScanner Tests**
   - Detect submodules with unpushed commits
   - Count unpushed commits correctly
   - Detect uncommitted changes
   - Handle submodules without remote tracking

2. **PushValidator Tests**
   - Validate remote tracking exists
   - Validate remote is configured
   - Detect authentication issues
   - Handle missing remotes gracefully

3. **PushExecutor Tests**
   - Build correct push commands
   - Handle dry-run mode
   - Handle force push flag
   - Parse git push output correctly
   - Detect various error conditions

4. **PushFormatter Tests**
   - Format progress messages
   - Format success/failure indicators
   - Format summary statistics
   - Handle dry-run output

### Integration Tests
1. **Full Push Flow**
   - Create test repository with submodules
   - Make commits in submodules
   - Run push command
   - Verify all pushes executed
   - Verify parent pushed last

2. **Error Scenarios**
   - Test push failure in middle submodule
   - Verify remaining submodules not pushed
   - Verify parent not pushed
   - Verify error message clarity

3. **Dry Run Mode**
   - Verify no actual pushes occur
   - Verify output shows what would be pushed
   - Verify exit code is 0

## Performance Considerations
- Sequential push execution (not parallel) for safety
- Expected runtime: ~1-5 seconds per submodule depending on network
- No caching needed (git operations are fast)
- Progress display prevents perception of hanging

## Security Considerations
- Never log credentials or authentication tokens
- Warn before force push operations
- Validate remote URLs to prevent malicious redirects
- Use git's built-in credential helpers

## Future Enhancements
- Parallel push execution with `--parallel` flag
- Push tags with `--tags` flag
- Interactive mode to select which submodules to push
- Retry logic for transient network failures
- Progress bars for large pushes

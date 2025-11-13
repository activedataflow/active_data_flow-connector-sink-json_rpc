# Design Document: Submoduler Git-Status Command

## Overview

The `git-status` command provides a unified view of git status across all submodules and the parent repository. It displays uncommitted changes, unpushed commits, branch information, and overall repository health in a single, easy-to-read format.

The design supports multiple display modes (compact, verbose, porcelain) and uses parallel execution for performance.

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    SubmodulerCLI                        │
│  - Parses command line arguments                        │
│  - Routes to GitStatusCommand                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                GitStatusCommand                         │
│  - Orchestrates status collection                       │
│  - Manages parallel execution                           │
└────────┬────────────────────────────────────────────────┘
         │
         ├──────────────┬──────────────┬─────────────────┐
         ▼              ▼              ▼                 ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│RepoStatus    │ │StatusCollector│ │StatusFormatter│ │StatusSummary │
│Checker       │ │              │ │              │ │              │
│              │ │              │ │              │ │              │
│- Checks      │ │- Collects    │ │- Formats     │ │- Aggregates  │
│  working     │ │  status from │ │  output      │ │  statistics  │
│  tree        │ │  all repos   │ │- Colors      │ │- Counts      │
│- Checks      │ │- Parallel    │ │- Modes       │ │- Summary     │
│  commits     │ │  execution   │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

## Components and Interfaces

### 1. GitStatusCommand

**Responsibility**: Orchestrate status collection and display

**Interface**:
```ruby
class GitStatusCommand
  def initialize(repo_root, options = {})
    @repo_root = repo_root
    @options = options
    @compact = options[:compact]
    @verbose = options[:verbose]
    @porcelain = options[:porcelain]
    @no_color = options[:no_color]
    @submodules = options[:submodules]
  end
  
  def execute
    # Returns exit code (0 for clean, 1 for dirty)
  end
  
  private
  
  def collect_status
    # Gather status from all repositories
  end
  
  def format_output(statuses)
    # Format and display results
  end
end
```

**Behavior**:
- Parse command line options
- Collect status from parent and all submodules
- Format output based on display mode
- Calculate and display summary statistics
- Return appropriate exit code

### 2. RepoStatusChecker

**Responsibility**: Check status of a single repository

**Interface**:
```ruby
class RepoStatusChecker
  def initialize(path, name: nil)
    @path = path
    @name = name
  end
  
  def check
    # Returns RepoStatus object
  end
  
  private
  
  def check_working_tree
    # Get uncommitted changes
  end
  
  def check_commits
    # Get unpushed/unpulled commits
  end
  
  def check_branch
    # Get branch information
  end
end

class RepoStatus
  attr_reader :name, :path, :branch, :uncommitted_files, 
              :commits_ahead, :commits_behind, :is_clean, 
              :is_initialized, :is_detached
  
  def initialize(attributes)
    # Initialize from hash
  end
  
  def clean?
    @is_clean
  end
  
  def dirty?
    !@is_clean
  end
end
```

**Behavior**:
- Run `git status --porcelain` to get working tree status
- Run `git rev-list --left-right --count @{u}...HEAD` for commit counts
- Run `git branch --show-current` for branch name
- Parse git output and build RepoStatus object
- Handle uninitialized submodules gracefully

### 3. StatusCollector

**Responsibility**: Collect status from all repositories

**Interface**:
```ruby
class StatusCollector
  def initialize(repo_root, gitmodules_parser, submodule_filter: nil)
    @repo_root = repo_root
    @parser = gitmodules_parser
    @filter = submodule_filter
  end
  
  def collect
    # Returns array of RepoStatus objects
  end
  
  private
  
  def collect_parallel
    # Collect status in parallel
  end
  
  def collect_sequential
    # Collect status sequentially (fallback)
  end
end
```

**Behavior**:
- Parse `.gitmodules` to get submodule list
- Filter submodules if `--submodule` flag provided
- Create RepoStatusChecker for each repository
- Execute checks in parallel using threads
- Collect parent repository status
- Return array of all statuses

### 4. StatusFormatter

**Responsibility**: Format status output

**Interface**:
```ruby
class StatusFormatter
  def initialize(statuses, options = {})
    @statuses = statuses
    @compact = options[:compact]
    @verbose = options[:verbose]
    @porcelain = options[:porcelain]
    @no_color = options[:no_color]
  end
  
  def format
    # Returns formatted string
  end
  
  private
  
  def format_compact
    # Compact display mode
  end
  
  def format_verbose
    # Verbose display mode
  end
  
  def format_porcelain
    # Machine-readable format
  end
  
  def colorize(text, color)
    # Add ANSI color codes
  end
end
```

**Behavior**:
- Choose formatting method based on display mode
- Apply colors unless `--no-color` specified
- Group repositories by status (clean vs dirty)
- Display file-level details in verbose mode
- Use consistent format in porcelain mode

### 5. StatusSummary

**Responsibility**: Calculate and format summary statistics

**Interface**:
```ruby
class StatusSummary
  def initialize(statuses)
    @statuses = statuses
  end
  
  def generate
    # Returns summary hash
  end
  
  private
  
  def count_clean
    # Count clean repositories
  end
  
  def count_dirty
    # Count dirty repositories
  end
  
  def total_uncommitted
    # Sum uncommitted files
  end
  
  def total_unpushed
    # Sum unpushed commits
  end
end
```

**Behavior**:
- Count clean vs dirty repositories
- Sum total uncommitted files
- Sum total unpushed commits
- Count uninitialized submodules
- Return structured summary data

## Data Models

### RepoStatus
```ruby
{
  name: "core_gem/core",
  path: "submodules/core/core",
  branch: "main",
  remote_branch: "origin/main",
  is_detached: false,
  is_initialized: true,
  is_clean: false,
  uncommitted_files: [
    { path: "lib/core.rb", status: "M" },
    { path: "spec/new_spec.rb", status: "??" }
  ],
  commits_ahead: 2,
  commits_behind: 0,
  unpushed_commits: [
    { sha: "abc123", message: "Add new feature" },
    { sha: "def456", message: "Fix bug" }
  ]
}
```

### StatusSummary
```ruby
{
  total_repos: 5,
  clean_repos: 2,
  dirty_repos: 3,
  uninitialized_repos: 0,
  total_uncommitted_files: 7,
  total_unpushed_commits: 5,
  total_unpulled_commits: 0
}
```

## Display Modes

### Normal Mode
```
Submodule Status Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Parent Repository (main)
  ✓ Clean - No uncommitted changes
  ✓ Up to date with origin/main

📦 core_gem/core (main)
  ✗ 2 uncommitted files:
    M  lib/core.rb
    ?? spec/new_spec.rb
  ⚠ 2 commits ahead of origin/main

📦 runtime_gems/rails_heartbeat_app (main)
  ✓ Clean - No uncommitted changes
  ✓ Up to date with origin/main

📦 connector_gems/active_record (feature-branch)
  ✓ Clean - No uncommitted changes
  ⚠ No remote tracking configured

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: 2 clean, 2 dirty, 2 uncommitted files, 2 unpushed commits
```

### Compact Mode
```
✓ Parent Repository (main)
✗ core_gem/core (main) - 2 uncommitted, 2 ahead
✓ runtime_gems/rails_heartbeat_app (main)
⚠ connector_gems/active_record (feature-branch) - no tracking

Summary: 2 clean, 2 dirty
```

### Verbose Mode
```
📦 core_gem/core (main → origin/main)
  Branch: main
  Remote: origin/main
  Status: 2 commits ahead, 0 behind
  
  Uncommitted Changes:
    M  lib/core.rb
       - Modified 15 lines
    ?? spec/new_spec.rb
       - New file, 42 lines
  
  Unpushed Commits:
    abc123 (2 hours ago) - Add new feature
           Author: John Doe <john@example.com>
    def456 (1 hour ago) - Fix bug
           Author: John Doe <john@example.com>
```

### Porcelain Mode
```
parent|main|origin/main|0|0|0|0
core_gem/core|main|origin/main|2|0|2|0
runtime_gems/rails_heartbeat_app|main|origin/main|0|0|0|0
connector_gems/active_record|feature-branch||0|0|0|0
```

Format: `name|branch|remote|uncommitted|untracked|ahead|behind`

## Performance Optimization

### Parallel Execution
```ruby
def collect_parallel
  threads = @submodules.map do |submodule|
    Thread.new do
      checker = RepoStatusChecker.new(submodule.path, name: submodule.name)
      checker.check
    end
  end
  
  threads.map(&:value)
end
```

**Benefits**:
- Check multiple submodules simultaneously
- Reduce total execution time from O(n) to O(1) for n submodules
- Typical speedup: 3-5x for repositories with 5+ submodules

**Considerations**:
- Thread pool size limit (default: 10 concurrent threads)
- Timeout per repository (default: 5 seconds)
- Fallback to sequential on thread errors

## Command Line Options

### Flags
- `--compact`: Condensed output showing only dirty repos
- `--verbose`: Detailed output with commit messages
- `--porcelain`: Machine-readable output
- `--no-color`: Disable color output
- `--submodule <name>`: Filter by submodule name
- `--timeout <seconds>`: Set timeout for status checks

### Examples
```bash
# Normal status display
submoduler.rb git-status

# Compact view
submoduler.rb git-status --compact

# Verbose with commit details
submoduler.rb git-status --verbose

# Machine-readable format
submoduler.rb git-status --porcelain

# Check specific submodules
submoduler.rb git-status --submodule core_gem/core

# No colors for piping
submoduler.rb git-status --no-color
```

## Testing Strategy

### Unit Tests
1. **RepoStatusChecker Tests**
   - Test parsing git status output
   - Test parsing commit counts
   - Test branch detection
   - Test detached HEAD detection
   - Test uninitialized repository handling

2. **StatusCollector Tests**
   - Test parallel collection
   - Test sequential fallback
   - Test submodule filtering
   - Test timeout handling

3. **StatusFormatter Tests**
   - Test normal mode formatting
   - Test compact mode formatting
   - Test verbose mode formatting
   - Test porcelain mode formatting
   - Test color application

4. **StatusSummary Tests**
   - Test counting clean/dirty repos
   - Test summing uncommitted files
   - Test summing unpushed commits
   - Test uninitialized repo counting

### Integration Tests
1. **Full Status Flow**
   - Create test repository with submodules
   - Make various changes (uncommitted, unpushed)
   - Run status command
   - Verify output format and accuracy

2. **Display Modes**
   - Test each display mode produces correct output
   - Verify compact mode omits clean repos
   - Verify verbose mode includes commit details
   - Verify porcelain mode is parseable

3. **Performance**
   - Test parallel execution is faster than sequential
   - Verify timeout handling works
   - Test with 10+ submodules

## Exit Code Semantics
- `0`: All repositories are clean
- `1`: One or more repositories have uncommitted changes or unpushed commits
- `2`: Invalid arguments or not a git repository

## Future Enhancements
- Watch mode with `--watch` flag for continuous monitoring
- JSON output format with `--json` flag
- Integration with git hooks for automatic status checks
- Desktop notifications for status changes
- Web dashboard for team-wide status visibility

# Implementation Plan

- [ ] 1. Create core data structures
  - Implement `RepoStatus` class with all status attributes
  - Implement `StatusSummary` class for aggregated statistics
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 2. Implement RepoStatusChecker
  - [ ] 2.1 Create RepoStatusChecker class structure
    - Implement `initialize` method accepting path and name
    - Implement main `check` method returning RepoStatus
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ] 2.2 Implement working tree status check
    - Execute `git status --porcelain` to get file changes
    - Parse output to identify modified, added, deleted, untracked files
    - Group files by status type
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [ ] 2.3 Implement commit status check
    - Execute `git rev-list --left-right --count @{u}...HEAD` for ahead/behind counts
    - Parse output to get commits ahead and behind
    - Handle repositories without remote tracking
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 2.4 Implement branch information check
    - Execute `git branch --show-current` for branch name
    - Execute `git rev-parse --abbrev-ref @{u}` for remote tracking branch
    - Detect detached HEAD state
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [ ] 2.5 Handle uninitialized submodules
    - Detect when submodule directory doesn't exist
    - Detect when submodule lacks `.git` file
    - Return appropriate status for uninitialized repos
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ] 3. Implement StatusCollector
  - [ ] 3.1 Create StatusCollector class structure
    - Implement `initialize` method accepting repo_root and parser
    - Implement main `collect` method returning status array
    - Support submodule filtering
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ] 3.2 Implement parallel status collection
    - Create thread pool for concurrent status checks
    - Execute RepoStatusChecker for each submodule in parallel
    - Collect and aggregate results
    - Implement timeout mechanism
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [ ] 3.3 Implement sequential fallback
    - Detect thread errors and fall back to sequential
    - Execute checks one at a time
    - Maintain same result format
    - _Requirements: 13.1, 13.2, 13.3_
  
  - [ ] 3.4 Implement parent repository status
    - Check parent repository status separately
    - Include parent in results array
    - Handle parent-specific status indicators
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 4. Implement StatusFormatter
  - [ ] 4.1 Create StatusFormatter class structure
    - Implement `initialize` method accepting statuses and options
    - Implement main `format` method returning formatted string
    - Support multiple display modes
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ] 4.2 Implement normal mode formatting
    - Display header with report title
    - Show each repository with status details
    - Use visual indicators (✓, ✗, ⚠)
    - Group uncommitted files by type
    - Display commit ahead/behind counts
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_
  
  - [ ] 4.3 Implement compact mode formatting
    - Show only repositories with changes
    - Display one line per repository
    - Include summary counts inline
    - Omit file-level details
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ] 4.4 Implement verbose mode formatting
    - Display full file paths
    - Show commit messages for unpushed commits
    - Include author and date information
    - Display detailed branch information
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 4.5 Implement porcelain mode formatting
    - Output in machine-readable format
    - Use consistent field separators
    - Omit colors and decorative elements
    - Document format specification
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [ ] 4.6 Implement color support
    - Use green for clean status
    - Use red for modified files and errors
    - Use yellow for warnings and untracked files
    - Use blue for staged changes
    - Support `--no-color` flag
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 5. Implement StatusSummary
  - Create StatusSummary class for aggregating statistics
  - Count clean vs dirty repositories
  - Sum total uncommitted files across all repos
  - Sum total unpushed commits across all repos
  - Count uninitialized submodules
  - Format summary section for display
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 6. Implement GitStatusCommand orchestrator
  - [ ] 6.1 Create GitStatusCommand class structure
    - Implement `initialize` method accepting repo_root and options
    - Parse command line options (compact, verbose, porcelain, no-color)
    - Implement main `execute` method returning exit code
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_
  
  - [ ] 6.2 Implement status collection orchestration
    - Instantiate StatusCollector with appropriate filters
    - Collect status from all repositories
    - Handle collection errors gracefully
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ] 6.3 Implement output formatting
    - Select formatter based on display mode
    - Generate formatted output
    - Display to stdout
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.1, 7.2, 7.3, 11.1, 11.2_
  
  - [ ] 6.4 Implement clean status handling
    - Detect when all repositories are clean
    - Display success message
    - Exit with code 0
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 6.5 Implement exit code logic
    - Return 0 when all repos are clean
    - Return 1 when any repo has changes or unpushed commits
    - Return 2 for invalid arguments or errors
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ] 7. Implement submodule filtering
  - Parse `--submodule` flags from command line
  - Validate specified submodules exist
  - Filter status collection to specified submodules
  - Always include parent repository status
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 8. Add CLI integration
  - Add `git-status` command to SubmodulerCLI
  - Parse git-status-specific command line options
  - Route to GitStatusCommand
  - Display usage information
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ]* 9. Write unit tests
  - [ ]* 9.1 Test RepoStatusChecker
    - Test parsing git status output
    - Test parsing commit counts
    - Test branch detection
    - Test detached HEAD detection
    - Test uninitialized repository handling
    - _Requirements: 1.1, 2.1, 3.1, 8.1, 12.1_
  
  - [ ]* 9.2 Test StatusCollector
    - Test parallel collection
    - Test sequential fallback
    - Test submodule filtering
    - Test timeout handling
    - _Requirements: 1.1, 10.1, 13.1, 13.2_
  
  - [ ]* 9.3 Test StatusFormatter
    - Test normal mode formatting
    - Test compact mode formatting
    - Test verbose mode formatting
    - Test porcelain mode formatting
    - Test color application
    - _Requirements: 6.1, 7.1, 9.1, 11.1_
  
  - [ ]* 9.4 Test StatusSummary
    - Test counting clean/dirty repos
    - Test summing uncommitted files
    - Test summing unpushed commits
    - _Requirements: 14.1, 14.2, 14.3_

- [ ]* 10. Write integration tests
  - Create test repository with submodules
  - Test full status flow with various changes
  - Test each display mode
  - Test submodule filtering
  - Test performance with parallel execution
  - Verify exit codes
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

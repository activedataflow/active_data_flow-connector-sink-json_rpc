# Implementation Plan: Submoduler Release Management

- [x] 1. Create ReleaseCommand class
  - Implement message validation (require -m/--message option)
  - Implement version synchronization step using VersionCommand with --sync
  - Implement commit step using GitAddCommand and GitCommitCommand
  - Implement test execution step using TestCommand
  - Implement push step using PushCommand (only if tests pass)
  - Implement --dry-run mode showing what would happen at each step
  - Implement --submodule filtering passed to all sub-commands
  - Display progress messages for each step
  - Handle failures at each step with appropriate error messages
  - Provide rollback guidance when tests fail after commits
  - Return exit code 0 for success, 1 for workflow failures, 2 for missing message
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.3, 8.4_

- [x] 2. Integrate release command into CLI
  - Add 'release' case to CLI command handler
  - Update show_usage help text with release command documentation
  - Add release command examples to help text
  - _Requirements: 1.1, 1.3_

- [x] 3. Test release workflow
  - Test that release requires message (fails without -m)
  - Test --dry-run mode shows preview without executing
  - Test successful release workflow (sync → commit → test → push)
  - Test failure handling when tests fail (commits not pushed)
  - Test --submodule filtering works across all steps
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 4.1, 6.1, 7.1_

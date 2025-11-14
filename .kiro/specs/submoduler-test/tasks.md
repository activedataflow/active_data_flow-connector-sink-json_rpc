# Implementation Plan: Submoduler Test Management

- [x] 1. Create TestRunner class
  - Implement test directory detection (spec/ or test/)
  - Implement test command detection (bundle exec rspec, rspec, rake spec)
  - Implement bundle install execution when Gemfile exists
  - Implement test execution with output capture
  - Handle errors gracefully (command not found, bundle install fails)
  - Return structured test result hash with status, output, duration
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 4.1, 4.2_

- [x] 2. Create TestFormatter class
  - Implement table formatting for test results with columns: submodule, status, duration
  - Implement color coding (green for passed, red for failed, yellow for skipped)
  - Implement failure details section showing output for failed tests
  - Implement summary showing pass/fail/skip counts
  - Support verbose mode to show all output
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.2, 5.3_

- [x] 3. Create TestCommand class
  - Implement command initialization with repo_root and options
  - Implement test execution workflow using TestRunner for each submodule
  - Implement --submodule filtering to target specific submodules
  - Skip submodules without tests (no spec/ or test/ directory)
  - Skip uninitialized submodules
  - Use TestFormatter to display results
  - Return exit code 0 when all tests pass, 1 when any test fails
  - _Requirements: 1.1, 2.5, 3.1, 3.2, 3.3, 4.3_

- [x] 4. Integrate test command into CLI
  - Add 'test' case to CLI command handler
  - Update show_usage help text with test command documentation
  - Add test command examples to help text
  - _Requirements: 1.1_

- [x] 5. Test the test command across existing submodules
  - Run test command on actual submodules to verify execution
  - Verify test detection works for submodules with spec/ directories
  - Verify skipping works for submodules without tests
  - Test --verbose mode shows detailed output
  - Test --submodule filtering works correctly
  - _Requirements: 1.1, 1.2, 3.1, 4.1, 5.1_

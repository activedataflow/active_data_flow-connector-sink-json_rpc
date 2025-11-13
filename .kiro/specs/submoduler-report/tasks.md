# Implementation Plan

- [x] 1. Create core data structures and models
  - Implement `SubmoduleEntry` class to represent parsed submodule configuration
  - Implement `ValidationResult` class to represent validation check outcomes
  - _Requirements: 1.3, 2.5, 3.5_

- [x] 2. Implement GitModulesParser
  - [x] 2.1 Create GitModulesParser class with file reading capability
    - Implement `initialize` method accepting repo_root parameter
    - Implement `exists?` method to check for .gitmodules file
    - Implement file reading logic for .gitmodules
    - _Requirements: 1.1, 1.2_
  
  - [x] 2.2 Implement .gitmodules parsing logic
    - Write regex patterns to match `[submodule "name"]` sections
    - Extract `path` and `url` key-value pairs from each section
    - Build and return array of SubmoduleEntry objects
    - Handle malformed files with appropriate error messages
    - _Requirements: 1.3, 5.4, 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [x] 2.3 Add malformed entry detection
    - Detect duplicate `path =` prefix in path values
    - Detect duplicate `url =` prefix in url values
    - Raise descriptive error with submodule name and line content
    - Fail fast when malformed entries are detected
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [x] 2.4 Add missing field validation
    - Verify each submodule entry has a path field
    - Verify each submodule entry has a url field
    - Raise error identifying which submodule and which field is missing
    - Fail fast when incomplete entries are detected
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 3. Implement PathValidator
  - [x] 3.1 Create PathValidator class structure
    - Implement `initialize` method accepting repo_root and submodule_entries
    - Implement main `validate` method that returns ValidationResult array
    - _Requirements: 2.1, 2.5_
  
  - [x] 3.2 Implement path existence checks
    - Write `check_path_exists` method using File.directory?
    - Write `check_path_is_relative` method to validate path format
    - Generate ValidationResult objects for each check
    - Include helpful failure messages with actual vs expected paths
    - _Requirements: 2.2, 2.3, 2.4, 5.2_

- [x] 4. Implement InitValidator
  - [x] 4.1 Create InitValidator class structure
    - Implement `initialize` method accepting repo_root and submodule_entries
    - Implement main `validate` method that returns ValidationResult array
    - _Requirements: 3.1, 3.5_
  
  - [x] 4.2 Implement initialization checks
    - Write `check_git_present` method to detect .git file or directory
    - Write `check_directory_empty` method to check for content
    - Generate ValidationResult objects distinguishing "not initialized" from "not checked out"
    - _Requirements: 3.2, 3.3, 3.4, 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 5. Implement ReportFormatter
  - [x] 5.1 Create ReportFormatter class with basic structure
    - Implement `initialize` method accepting validation results
    - Implement main `format` method that returns formatted string
    - _Requirements: 4.2, 4.3_
  
  - [x] 5.2 Implement output formatting methods
    - Write `format_header` method with title and timestamp
    - Write `format_section` method to group results by validation type
    - Write `format_summary` method with pass/fail counts
    - Write `colorize` method to add ANSI color codes (green for pass, red for fail)
    - Use ✓ and ✗ symbols for visual indicators
    - Display submodule names consistently using exact format from `.gitmodules`
    - _Requirements: 4.1, 4.3, 4.4, 14.1, 14.2, 14.3, 14.4, 14.5_

- [x] 6. Implement ReportCommand orchestrator
  - [x] 6.1 Create ReportCommand class structure
    - Implement `initialize` method accepting repo_root
    - Implement main `execute` method that returns exit code
    - _Requirements: 4.5_
  
  - [x] 6.2 Implement validation orchestration
    - Instantiate GitModulesParser and parse submodule entries
    - Instantiate PathValidator and run path validations
    - Instantiate InitValidator and run initialization checks
    - Collect all ValidationResult objects before reporting
    - Continue validation even when individual checks fail
    - Pass results to ReportFormatter and display output
    - Return exit code 0 if all pass, 1 if any fail
    - _Requirements: 1.4, 1.5, 5.5, 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 7. Implement SubmodulerCLI entry point
  - [x] 7.1 Create SubmodulerCLI class with argument parsing
    - Implement `run` class method accepting args array
    - Implement `parse_command` method to extract command name
    - Implement `show_usage` method to display help text
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 7.2 Implement repository root detection
    - Search for `.git` directory starting from current directory
    - Walk up parent directories until `.git` is found or filesystem root reached
    - Raise error if not running from within a git repository
    - Use detected repository root for all path operations
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [x] 7.3 Implement command routing and exit codes
    - Route to ReportCommand when "report" command is specified
    - Handle invalid commands with usage display
    - Return exit code 0 for success or no submodules
    - Return exit code 1 for validation failures
    - Return exit code 2 for script errors and malformed config
    - _Requirements: 6.4, 6.5, 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 8. Create executable script wrapper
  - Create `bin/submoduler.rb` executable file with shebang
  - Require all necessary classes
  - Call SubmodulerCLI.run(ARGV) and exit with returned code
  - Make file executable with proper permissions
  - _Requirements: 6.4_

- [x] 9. Add error handling throughout
  - Add file system error handling (permissions, missing files)
  - Distinguish between "file not found" and "permission denied" errors
  - Add malformed configuration handling with helpful messages
  - Continue validation for other submodules when one fails
  - Include system error messages in diagnostic output
  - Ensure all errors include actionable remediation suggestions
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 15.1, 15.2, 15.3, 15.4, 15.5_

- [x] 10. Write unit tests for core components
  - [x] 10.1 Write tests for GitModulesParser
    - Test parsing valid .gitmodules file
    - Test handling missing .gitmodules file
    - Test detecting duplicate `path =` prefix
    - Test detecting duplicate `url =` prefix
    - Test error for missing path field
    - Test error for missing url field
    - Verify submodule name included in error messages
    - _Requirements: 1.3, 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [x] 10.2 Write tests for PathValidator
    - Test detecting existing paths (pass)
    - Test detecting missing paths (fail)
    - Test detecting absolute paths (fail)
    - Test handling permission errors gracefully
    - _Requirements: 2.5, 15.1, 15.2, 15.3_
  
  - [x] 10.3 Write tests for InitValidator
    - Test detecting initialized submodules (pass)
    - Test detecting uninitialized submodules (fail)
    - Test detecting empty directories (fail)
    - Test handling missing directories gracefully
    - _Requirements: 3.5, 10.1, 10.2, 10.3, 10.4, 10.5_
  
  - [x] 10.4 Write tests for ReportFormatter
    - Test formatting pass results with green checkmark
    - Test formatting fail results with red X
    - Test generating correct summary counts
    - Test grouping results by validation type
    - Test displaying submodule names consistently
    - _Requirements: 4.4, 14.1, 14.2, 14.3, 14.4_

- [x] 11. Write integration tests
  - Create test repository fixture with .gitmodules
  - Test full report generation with mixed valid/invalid submodules
  - Test edge cases (no .gitmodules, all valid, all invalid)
  - Test malformed .gitmodules with duplicate keys
  - Test missing required fields in submodule entries
  - Verify output format and exit codes (0, 1, 2)
  - Verify all validation results collected before reporting
  - _Requirements: 4.5, 5.5, 12.1, 12.2, 12.3, 12.4, 12.5, 13.1, 13.2, 13.3, 13.4, 13.5_

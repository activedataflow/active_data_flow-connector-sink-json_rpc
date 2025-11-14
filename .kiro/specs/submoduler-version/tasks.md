# Implementation Plan: Submoduler Version Management

- [x] 1. Create GemVersionDetector class
  - Implement gemspec file discovery in submodule directory
  - Implement version extraction from gemspec files using regex patterns
  - Implement version.rb file discovery and parsing
  - Handle multiple module nesting patterns (e.g., ActiveDataFlow::Core::VERSION)
  - Return structured version information hash
  - Handle errors gracefully when files are missing
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Create GemVersionUpdater class
  - Implement version string parsing (semantic versioning)
  - Implement version increment logic (add 0.0.1 to highest version)
  - Implement version.rb file update with regex replacement
  - Preserve existing file format and indentation
  - Handle nested module structures when updating
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Create VersionFormatter class
  - Implement table formatting for version display with columns: submodule, gem name, version
  - Implement color coding (green for matching, red for mismatched versions)
  - Implement mismatch warning section showing highest version
  - Implement sync summary showing which submodules were updated
  - Implement dry-run output format
  - _Requirements: 1.4, 2.3, 3.5, 4.2_

- [x] 4. Create VersionCommand class
  - Implement command initialization with repo_root and options
  - Implement version detection workflow using GemVersionDetector for each submodule
  - Implement version comparison logic to find highest version and detect mismatches
  - Implement --sync flag handling to trigger version synchronization
  - Implement --dry-run mode that shows changes without applying them
  - Implement --submodule filtering to target specific submodules
  - Use VersionFormatter to display results
  - Return appropriate exit codes (0 for success/match, 1 for mismatch, 2 for errors)
  - _Requirements: 1.1, 2.1, 2.2, 2.4, 2.5, 3.1, 4.1, 4.3, 5.1, 5.2, 5.3_

- [x] 5. Integrate version command into CLI
  - Add 'version' case to CLI command handler
  - Add --sync option to parse_command_and_options method
  - Update show_usage help text with version command documentation
  - Add version command examples to help text
  - _Requirements: 1.1, 3.1, 4.1_

- [x] 6. Test version detection across existing submodules
  - Run version command on actual submodules to verify detection
  - Verify gemspec parsing works for all submodule formats
  - Verify version extraction from version.rb files
  - Test error handling for submodules without gemspecs
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 7. Test version synchronization workflow
  - Test --sync flag updates all versions correctly
  - Verify version increment logic (0.0.1 past highest)
  - Verify files are updated with correct version strings
  - Test --dry-run shows changes without applying them
  - Test --submodule filtering works correctly
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 5.1, 5.2_

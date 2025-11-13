# Implementation Plan

- [ ] 1. Create core data structures
  - Implement `AddOperation` class
  - Implement `AddResult` class
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 2. Implement FileScanner
  - [ ] 2.1 Create FileScanner class
    - Scan for modified/untracked files
    - Apply pattern matching
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 2.2 Implement pattern matching
    - Support glob patterns
    - Match files across submodules
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 3. Implement AddExecutor
  - [ ] 3.1 Create AddExecutor class
    - Build git add commands
    - Execute in submodule directories
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ] 3.2 Implement operation modes
    - Support --all flag
    - Support --update flag
    - Support --force flag
    - Support --intent-to-add flag
    - _Requirements: 1.1, 7.1, 8.1, 9.1_
  
  - [ ] 3.3 Implement interactive mode
    - Prompt for each file
    - Accept y/n/q responses
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 3.4 Implement patch mode
    - Display change hunks
    - Allow hunk-level staging
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 3.5 Implement dry-run mode
    - Skip actual staging
    - Display what would be staged
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 4. Implement GitAddCommand orchestrator
  - [ ] 4.1 Create GitAddCommand class
    - Parse command line options
    - Orchestrate add operations
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_
  
  - [ ] 4.2 Implement selective submodule add
    - Filter by --submodule flag
    - Validate submodules exist
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [ ] 4.3 Implement parent reference update
    - Detect submodule reference changes
    - Stage references in parent
    - Support --no-parent flag
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 5. Implement progress reporting
  - Display current submodule being processed
  - Show file counts
  - Display summary
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 6. Implement error handling
  - Capture git add errors
  - Continue processing after errors
  - Report failures clearly
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 7. Add CLI integration
  - Add `git-add` command to SubmodulerCLI
  - Parse options
  - Route to GitAddCommand
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ]* 8. Write unit tests
  - Test FileScanner pattern matching
  - Test AddExecutor command building
  - Test interactive mode
  - Test patch mode
  - _Requirements: 1.1, 3.1, 4.1, 5.1_

- [ ]* 9. Write integration tests
  - Test full add flow
  - Test selective submodule add
  - Test parent reference update
  - Test error scenarios
  - _Requirements: 15.1, 15.2, 15.3_


# Requirements Document

## Introduction

The submoduler-release feature provides an automated release workflow for all submodules in a monorepo. It orchestrates version synchronization, testing, committing, and pushing changes to ensure a consistent and validated release across all submodules.

## Glossary

- **Submoduler**: The git submodule management tool
- **Release Command**: A CLI command that orchestrates the complete release workflow
- **Release Message**: A required commit message describing the release changes
- **Version Synchronization**: The process of ensuring all submodules have consistent versions
- **Release Workflow**: The sequence of steps: version sync, commit, test, and push

## Requirements

### Requirement 1: Release Message Requirement

**User Story:** As a developer, I want to provide a release message, so that all commits have meaningful descriptions

#### Acceptance Criteria

1. WHEN the user executes `submoduler.rb release` without `-m` or `--message` option, THE Release Command SHALL display an error and exit with code 2
2. THE Release Command SHALL require the message to be non-empty
3. WHEN the user provides `-m <message>` option, THE Release Command SHALL use that message for all commits
4. THE Release Command SHALL display the error message "Error: Release message is required. Use -m or --message option"

### Requirement 2: Version Synchronization Step

**User Story:** As a developer, I want versions to be automatically synchronized during release, so that all submodules have consistent versions

#### Acceptance Criteria

1. WHEN the Release Command executes, THE Release Command SHALL first check for version mismatches across submodules
2. WHEN version mismatches are detected, THE Release Command SHALL increment all versions to 0.0.1 past the highest found version
3. THE Release Command SHALL update version files in all submodules with mismatched versions
4. WHEN all versions already match, THE Release Command SHALL skip version synchronization
5. THE Release Command SHALL report which submodules had versions updated

### Requirement 3: Commit All Changes Step

**User Story:** As a developer, I want all changes to be committed automatically during release, so that the release is atomic

#### Acceptance Criteria

1. AFTER version synchronization completes, THE Release Command SHALL stage all changes in each submodule
2. THE Release Command SHALL commit changes in each submodule using the provided release message
3. THE Release Command SHALL update the parent repository to reference the new submodule commits
4. THE Release Command SHALL commit the parent repository changes with the same release message
5. WHEN a submodule has no changes to commit, THE Release Command SHALL skip that submodule

### Requirement 4: Test All Submodules Step

**User Story:** As a developer, I want all tests to run before pushing, so that I don't release broken code

#### Acceptance Criteria

1. AFTER all commits are created, THE Release Command SHALL execute the test suite for each submodule
2. WHEN any test fails, THE Release Command SHALL halt the release process and exit with code 1
3. THE Release Command SHALL display which submodule's tests failed
4. WHEN all tests pass, THE Release Command SHALL proceed to the push step
5. THE Release Command SHALL report "All tests passed" before pushing

### Requirement 5: Push All Changes Step

**User Story:** As a developer, I want changes to be pushed automatically after tests pass, so that the release is completed

#### Acceptance Criteria

1. WHEN all tests pass, THE Release Command SHALL push each submodule to its remote repository
2. THE Release Command SHALL push to the default remote (origin) for each submodule
3. AFTER all submodules are pushed, THE Release Command SHALL push the parent repository
4. THE Release Command SHALL report successful push for each submodule
5. THE Release Command SHALL exit with code 0 when the entire release workflow succeeds

### Requirement 6: Dry Run Mode

**User Story:** As a developer, I want to preview the release workflow without executing it, so that I can verify the process

#### Acceptance Criteria

1. WHEN the user provides `--dry-run` option, THE Release Command SHALL display all steps that would be executed without making changes
2. THE Release Command SHALL show which versions would be updated
3. THE Release Command SHALL show which commits would be created
4. THE Release Command SHALL indicate that tests would be run but not actually run them
5. THE Release Command SHALL exit with code 0 in dry-run mode

### Requirement 7: Selective Submodule Release

**User Story:** As a developer, I want to release specific submodules only, so that I can make targeted releases

#### Acceptance Criteria

1. WHEN the user provides `--submodule <name>` option, THE Release Command SHALL execute the release workflow only for specified submodules
2. THE Release Command SHALL support multiple `--submodule` options
3. WHEN specific submodules are targeted, THE Release Command SHALL only synchronize versions among those submodules
4. THE Release Command SHALL still update and push the parent repository to reflect submodule changes

### Requirement 8: Rollback on Failure

**User Story:** As a developer, I want clear guidance when a release fails, so that I can recover from errors

#### Acceptance Criteria

1. WHEN tests fail after commits are created, THE Release Command SHALL display a message explaining that commits exist but were not pushed
2. THE Release Command SHALL provide instructions for rolling back commits if needed
3. THE Release Command SHALL not attempt to push any submodules when tests fail
4. THE Release Command SHALL exit with code 1 when the release workflow fails

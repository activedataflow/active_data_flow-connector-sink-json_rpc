# Requirements Document

## Introduction

This document specifies the requirements for the `push` command in the Submoduler tool. The `push` command automates the process of pushing changes from all modified submodules to their remote repositories, followed by pushing the parent repository. This ensures that submodule commits are available remotely before the parent repository references them.

The command is designed to prevent the common issue where a parent repository references submodule commits that haven't been pushed, causing checkout failures for other developers.

## Glossary

- **Submoduler**: The Ruby script tool for managing and validating git submodules
- **GitModules**: The `.gitmodules` configuration file that defines submodule mappings
- **SubmodulePath**: The local filesystem path where a submodule is checked out
- **ParentRepository**: The top-level git repository containing submodules
- **SubmoduleCommit**: A specific commit SHA that the parent repository references for a submodule
- **RemoteRepository**: The git server hosting the repository (e.g., GitHub, GitLab)
- **PushOperation**: The git operation that uploads local commits to a remote repository
- **DirtySubmodule**: A submodule with uncommitted changes or unpushed commits
- **SubmoduleReference**: The commit SHA stored in the parent repository's index for a submodule

## Requirements

### Requirement 1: Modified Submodule Detection

**User Story:** As a developer, I want to identify which submodules have unpushed commits, so that I know what needs to be pushed before updating the parent repository.

#### Acceptance Criteria

1. WHEN the push command runs, THE Submoduler SHALL identify all submodules with local commits
2. THE Submoduler SHALL compare each submodule's HEAD with its remote tracking branch
3. THE Submoduler SHALL detect submodules with commits ahead of their remote
4. THE Submoduler SHALL report the count of unpushed commits for each modified submodule
5. THE Submoduler SHALL display the submodule name and path for each modified submodule

### Requirement 2: Submodule Push Execution

**User Story:** As a developer, I want to push all modified submodules automatically, so that I don't have to manually enter each submodule directory.

#### Acceptance Criteria

1. WHEN modified submodules are detected, THE Submoduler SHALL push each submodule to its remote
2. THE Submoduler SHALL use the default remote (origin) for each submodule
3. THE Submoduler SHALL push the current branch of each submodule
4. THE Submoduler SHALL execute pushes sequentially, one submodule at a time
5. THE Submoduler SHALL display progress for each submodule push operation

### Requirement 3: Parent Repository Push

**User Story:** As a developer, I want the parent repository pushed after all submodules, so that submodule commits are available before the parent references them.

#### Acceptance Criteria

1. WHEN all submodule pushes succeed, THE Submoduler SHALL push the parent repository
2. THE Submoduler SHALL use the default remote (origin) for the parent repository
3. THE Submoduler SHALL push the current branch of the parent repository
4. THE Submoduler SHALL display the parent repository push progress
5. THE Submoduler SHALL exit with code 0 when all pushes succeed

### Requirement 4: Push Failure Handling

**User Story:** As a developer, I want clear error messages when pushes fail, so that I can understand and fix the problem.

#### Acceptance Criteria

1. IF a submodule push fails, THEN THE Submoduler SHALL display the error message
2. IF a submodule push fails, THEN THE Submoduler SHALL stop and not push remaining submodules
3. IF a submodule push fails, THEN THE Submoduler SHALL not push the parent repository
4. THE Submoduler SHALL include the submodule name in push failure messages
5. THE Submoduler SHALL exit with code 1 when any push operation fails

### Requirement 5: Dry Run Mode

**User Story:** As a developer, I want to preview what would be pushed without actually pushing, so that I can verify the operation before executing it.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--dry-run` flag for the push command
2. WHEN dry-run mode is enabled, THE Submoduler SHALL display what would be pushed
3. WHEN dry-run mode is enabled, THE Submoduler SHALL not execute any push operations
4. THE Submoduler SHALL show the number of commits that would be pushed for each submodule
5. THE Submoduler SHALL indicate whether the parent repository would be pushed

### Requirement 6: Uncommitted Changes Detection

**User Story:** As a developer, I want to be warned about uncommitted changes, so that I don't accidentally leave work unpushed.

#### Acceptance Criteria

1. WHEN a submodule has uncommitted changes, THE Submoduler SHALL display a warning
2. THE Submoduler SHALL list which files have uncommitted changes in each submodule
3. THE Submoduler SHALL continue with the push operation despite uncommitted changes
4. THE Submoduler SHALL distinguish between uncommitted changes and unpushed commits
5. THE Submoduler SHALL provide a summary of submodules with uncommitted changes

### Requirement 7: Remote Branch Tracking

**User Story:** As a developer, I want to ensure branches have remote tracking configured, so that pushes go to the correct remote branch.

#### Acceptance Criteria

1. WHEN a submodule branch lacks remote tracking, THE Submoduler SHALL detect this condition
2. THE Submoduler SHALL display a warning for branches without remote tracking
3. THE Submoduler SHALL suggest the appropriate git command to set up tracking
4. THE Submoduler SHALL skip pushing submodules without remote tracking
5. THE Submoduler SHALL continue processing other submodules after skipping one

### Requirement 8: Push Progress Reporting

**User Story:** As a developer, I want to see progress as pushes execute, so that I know the operation is working and not stuck.

#### Acceptance Criteria

1. THE Submoduler SHALL display a header before starting push operations
2. THE Submoduler SHALL show "Pushing submodule X of Y" for each submodule
3. THE Submoduler SHALL display the submodule name and commit count being pushed
4. THE Submoduler SHALL show a success indicator after each successful push
5. THE Submoduler SHALL display a final summary with total submodules and parent pushed

### Requirement 9: No Changes to Push

**User Story:** As a developer, I want to be informed when there's nothing to push, so that I don't waste time waiting for an unnecessary operation.

#### Acceptance Criteria

1. WHEN no submodules have unpushed commits, THE Submoduler SHALL report this status
2. WHEN the parent repository has no unpushed commits, THE Submoduler SHALL report this status
3. THE Submoduler SHALL exit with code 0 when nothing needs to be pushed
4. THE Submoduler SHALL display a message indicating all repositories are up to date
5. THE Submoduler SHALL not execute any git push commands when nothing needs pushing

### Requirement 10: Force Push Protection

**User Story:** As a developer, I want protection against accidental force pushes, so that I don't overwrite remote history unintentionally.

#### Acceptance Criteria

1. THE Submoduler SHALL not use force push by default
2. THE Submoduler SHALL support a `--force` flag for force push operations
3. WHEN force push is requested, THE Submoduler SHALL display a warning
4. THE Submoduler SHALL require explicit confirmation for force push operations
5. THE Submoduler SHALL apply force push to both submodules and parent repository

### Requirement 11: Selective Submodule Push

**User Story:** As a developer, I want to push only specific submodules, so that I can control which changes are published.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--submodule` flag to specify which submodules to push
2. THE Submoduler SHALL accept multiple `--submodule` flags for multiple submodules
3. WHEN specific submodules are specified, THE Submoduler SHALL only push those submodules
4. THE Submoduler SHALL validate that specified submodules exist in `.gitmodules`
5. THE Submoduler SHALL still push the parent repository after pushing selected submodules

### Requirement 12: Remote Specification

**User Story:** As a developer, I want to push to a specific remote, so that I can publish changes to different remote repositories.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--remote` flag to specify the target remote
2. WHEN a remote is specified, THE Submoduler SHALL use it for all push operations
3. THE Submoduler SHALL validate that the specified remote exists
4. THE Submoduler SHALL apply the remote to both submodules and parent repository
5. THE Submoduler SHALL default to "origin" when no remote is specified

### Requirement 13: Exit Code Semantics

**User Story:** As a developer, I want meaningful exit codes, so that I can use the tool in scripts and CI/CD pipelines.

#### Acceptance Criteria

1. THE Submoduler SHALL exit with code 0 when all pushes succeed
2. THE Submoduler SHALL exit with code 0 when nothing needs to be pushed
3. THE Submoduler SHALL exit with code 1 when any push operation fails
4. THE Submoduler SHALL exit with code 2 when invalid arguments are provided
5. THE Submoduler SHALL exit with code 2 when not running from a git repository

### Requirement 14: Authentication Handling

**User Story:** As a developer, I want clear messages about authentication failures, so that I can resolve credential issues.

#### Acceptance Criteria

1. WHEN a push fails due to authentication, THE Submoduler SHALL detect this condition
2. THE Submoduler SHALL display a message indicating authentication is required
3. THE Submoduler SHALL suggest checking SSH keys or credential configuration
4. THE Submoduler SHALL include the remote URL in authentication error messages
5. THE Submoduler SHALL exit with code 1 for authentication failures

### Requirement 15: Atomic Operation Guarantee

**User Story:** As a developer, I want assurance that partial pushes are avoided, so that my repository state remains consistent.

#### Acceptance Criteria

1. WHEN any submodule push fails, THE Submoduler SHALL not push the parent repository
2. THE Submoduler SHALL not attempt to roll back successful submodule pushes
3. THE Submoduler SHALL clearly indicate which submodules were successfully pushed
4. THE Submoduler SHALL indicate which submodule push failed and why
5. THE Submoduler SHALL allow the developer to retry after fixing the issue

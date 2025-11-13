# Requirements Document

## Introduction

This document specifies the requirements for the `git-commit` command in the Submoduler tool. The `git-commit` command provides a streamlined way to commit changes across multiple submodules and the parent repository, with options for using the same commit message or individual messages.

The command is designed to simplify the workflow when making coordinated changes across multiple submodules, ensuring consistent commit messages and proper sequencing.

## Glossary

- **Submoduler**: The Ruby script tool for managing and validating git submodules
- **GitModules**: The `.gitmodules` configuration file that defines submodule mappings
- **CommitMessage**: The description of changes included in a commit
- **StagedChanges**: Changes in the staging area ready to be committed
- **CommitSHA**: The unique identifier for a commit
- **AtomicCommit**: A commit operation that either fully succeeds or fully fails
- **CommitHook**: A script that runs before or after a commit
- **AmendCommit**: Modifying the most recent commit instead of creating a new one
- **SignedCommit**: A commit with a GPG signature for verification

## Requirements

### Requirement 1: Unified Commit Message

**User Story:** As a developer, I want to use the same commit message across all submodules, so that I can describe coordinated changes consistently.

#### Acceptance Criteria

1. THE Submoduler SHALL accept a `-m` or `--message` flag for the commit message
2. WHEN a message is provided, THE Submoduler SHALL use it for all submodule commits
3. THE Submoduler SHALL commit each submodule with staged changes using the provided message
4. THE Submoduler SHALL commit the parent repository with the same message
5. THE Submoduler SHALL display which submodules were committed with the message

### Requirement 2: Individual Commit Messages

**User Story:** As a developer, I want to provide different commit messages for each submodule, so that I can describe submodule-specific changes accurately.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--interactive` flag for per-submodule messages
2. WHEN interactive mode is enabled, THE Submoduler SHALL prompt for a message for each submodule
3. THE Submoduler SHALL display the submodule name when prompting for a message
4. THE Submoduler SHALL allow skipping submodules with no staged changes
5. THE Submoduler SHALL prompt for a parent repository message after all submodules

### Requirement 3: Editor-Based Message Composition

**User Story:** As a developer, I want to compose commit messages in my editor, so that I can write detailed multi-line messages.

#### Acceptance Criteria

1. WHEN no message flag is provided, THE Submoduler SHALL open the configured git editor
2. THE Submoduler SHALL pre-populate the editor with a template showing affected submodules
3. THE Submoduler SHALL allow multi-line commit messages
4. THE Submoduler SHALL respect the git core.editor configuration
5. THE Submoduler SHALL abort the commit if the editor is closed without saving

### Requirement 4: Selective Submodule Commit

**User Story:** As a developer, I want to commit only specific submodules, so that I can control which changes are committed.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--submodule` flag to specify which submodules to commit
2. THE Submoduler SHALL accept multiple `--submodule` flags
3. WHEN specific submodules are specified, THE Submoduler SHALL only commit those submodules
4. THE Submoduler SHALL validate that specified submodules exist and have staged changes
5. THE Submoduler SHALL still commit the parent repository after committing selected submodules

### Requirement 5: Dry Run Mode

**User Story:** As a developer, I want to preview what would be committed without actually committing, so that I can verify the operation.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--dry-run` flag
2. WHEN dry-run mode is enabled, THE Submoduler SHALL display what would be committed
3. WHEN dry-run mode is enabled, THE Submoduler SHALL not create any commits
4. THE Submoduler SHALL show the commit message that would be used
5. THE Submoduler SHALL list which submodules would be committed

### Requirement 6: Amend Last Commit

**User Story:** As a developer, I want to amend the last commit in submodules, so that I can fix mistakes without creating new commits.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--amend` flag
2. WHEN amend mode is enabled, THE Submoduler SHALL amend the last commit in each submodule
3. THE Submoduler SHALL preserve the original commit message unless a new one is provided
4. THE Submoduler SHALL warn when amending commits that have been pushed
5. THE Submoduler SHALL amend the parent repository commit after amending submodules

### Requirement 7: Commit All Changes

**User Story:** As a developer, I want to commit all changes without staging first, so that I can save time on simple commits.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--all` flag to commit all changes
2. WHEN all mode is enabled, THE Submoduler SHALL stage and commit all tracked files
3. THE Submoduler SHALL not commit untracked files in all mode
4. THE Submoduler SHALL apply all mode to each submodule and the parent
5. THE Submoduler SHALL display which files were auto-staged in each submodule

### Requirement 8: Empty Commit Creation

**User Story:** As a developer, I want to create empty commits for triggering CI/CD, so that I can force pipeline execution.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--allow-empty` flag
2. WHEN allow-empty is enabled, THE Submoduler SHALL create commits even with no changes
3. THE Submoduler SHALL apply allow-empty to specified submodules or all submodules
4. THE Submoduler SHALL require a commit message for empty commits
5. THE Submoduler SHALL indicate which commits were created as empty

### Requirement 9: Signed Commits

**User Story:** As a developer, I want to sign commits with GPG, so that I can verify commit authenticity.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--gpg-sign` flag for signing commits
2. WHEN gpg-sign is enabled, THE Submoduler SHALL sign all commits with the configured key
3. THE Submoduler SHALL support specifying a key ID with `--gpg-sign=<keyid>`
4. THE Submoduler SHALL apply signing to both submodule and parent commits
5. THE Submoduler SHALL display an error if GPG signing fails

### Requirement 10: Commit Verification

**User Story:** As a developer, I want to verify that commits were created successfully, so that I can ensure my changes are saved.

#### Acceptance Criteria

1. THE Submoduler SHALL verify each commit was created successfully
2. THE Submoduler SHALL display the commit SHA for each successful commit
3. THE Submoduler SHALL show the short commit message for each commit
4. THE Submoduler SHALL indicate which submodules were committed
5. THE Submoduler SHALL provide a summary of total commits created

### Requirement 11: No Staged Changes Handling

**User Story:** As a developer, I want to be informed when there are no changes to commit, so that I don't waste time on unnecessary operations.

#### Acceptance Criteria

1. WHEN a submodule has no staged changes, THE Submoduler SHALL skip that submodule
2. THE Submoduler SHALL display a message indicating which submodules were skipped
3. WHEN no submodules have staged changes, THE Submoduler SHALL exit without committing
4. THE Submoduler SHALL exit with code 0 when nothing needs to be committed
5. THE Submoduler SHALL provide a summary of skipped vs committed submodules

### Requirement 12: Commit Hook Execution

**User Story:** As a developer, I want commit hooks to run for each submodule, so that validation and automation work correctly.

#### Acceptance Criteria

1. THE Submoduler SHALL execute pre-commit hooks for each submodule
2. THE Submoduler SHALL execute commit-msg hooks for each submodule
3. IF a pre-commit hook fails, THEN THE Submoduler SHALL abort that submodule's commit
4. THE Submoduler SHALL support a `--no-verify` flag to skip hooks
5. THE Submoduler SHALL report which submodules had hook failures

### Requirement 13: Author and Date Override

**User Story:** As a developer, I want to override commit author and date, so that I can maintain accurate attribution.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--author` flag to set commit author
2. THE Submoduler SHALL support a `--date` flag to set commit date
3. WHEN author is specified, THE Submoduler SHALL apply it to all commits
4. WHEN date is specified, THE Submoduler SHALL apply it to all commits
5. THE Submoduler SHALL validate author and date formats before committing

### Requirement 14: Verbose Output

**User Story:** As a developer, I want detailed output about what is being committed, so that I can verify the operation.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--verbose` flag for detailed output
2. WHEN verbose mode is enabled, THE Submoduler SHALL list files in each commit
3. THE Submoduler SHALL show the full commit message for each commit
4. THE Submoduler SHALL display git command output in verbose mode
5. THE Submoduler SHALL show commit statistics (insertions, deletions)

### Requirement 15: Exit Code Semantics

**User Story:** As a developer, I want meaningful exit codes, so that I can use the tool in scripts and CI/CD pipelines.

#### Acceptance Criteria

1. THE Submoduler SHALL exit with code 0 when all commits succeed
2. THE Submoduler SHALL exit with code 0 when nothing needs to be committed
3. THE Submoduler SHALL exit with code 1 when any commit fails
4. THE Submoduler SHALL exit with code 1 when commit hooks fail
5. THE Submoduler SHALL exit with code 2 when invalid arguments are provided

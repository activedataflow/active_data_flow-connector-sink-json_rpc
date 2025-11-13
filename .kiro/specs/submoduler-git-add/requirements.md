# Requirements Document

## Introduction

This document specifies the requirements for the `git-add` command in the Submoduler tool. The `git-add` command provides a convenient way to stage changes across multiple submodules and the parent repository in a single operation.

The command is designed to streamline the workflow when making changes across multiple submodules, eliminating the need to manually enter each directory to stage files.

## Glossary

- **Submoduler**: The Ruby script tool for managing and validating git submodules
- **GitModules**: The `.gitmodules` configuration file that defines submodule mappings
- **StagingArea**: The git index where changes are prepared for commit
- **WorkingTree**: The current state of files in the repository
- **ModifiedFile**: A tracked file that has been changed since the last commit
- **UntrackedFile**: A file that is not currently tracked by git
- **StagedChange**: A change that has been added to the staging area
- **InteractiveMode**: A mode where the user selects which changes to stage
- **PathSpec**: A pattern for matching file paths

## Requirements

### Requirement 1: Add All Changes

**User Story:** As a developer, I want to stage all changes across all submodules, so that I can quickly prepare a comprehensive commit.

#### Acceptance Criteria

1. WHEN the git-add command runs with `--all` flag, THE Submoduler SHALL stage all changes in all submodules
2. THE Submoduler SHALL stage modified files in each submodule
3. THE Submoduler SHALL stage deleted files in each submodule
4. THE Submoduler SHALL stage new files in each submodule
5. THE Submoduler SHALL stage changes in the parent repository

### Requirement 2: Selective Submodule Add

**User Story:** As a developer, I want to stage changes in specific submodules, so that I can control which changes are included.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--submodule` flag to specify which submodules to process
2. THE Submoduler SHALL accept multiple `--submodule` flags
3. WHEN specific submodules are specified, THE Submoduler SHALL only stage changes in those submodules
4. THE Submoduler SHALL validate that specified submodules exist in `.gitmodules`
5. THE Submoduler SHALL report which submodules had changes staged

### Requirement 3: Pattern-Based File Selection

**User Story:** As a developer, I want to stage files matching a pattern, so that I can add specific types of files across all submodules.

#### Acceptance Criteria

1. THE Submoduler SHALL accept file patterns as arguments (e.g., `*.rb`, `*.md`)
2. WHEN a pattern is provided, THE Submoduler SHALL stage matching files in all submodules
3. THE Submoduler SHALL support glob patterns for file matching
4. THE Submoduler SHALL apply patterns relative to each submodule's root
5. THE Submoduler SHALL report how many files matched the pattern in each submodule

### Requirement 4: Interactive Mode

**User Story:** As a developer, I want to interactively select which changes to stage, so that I can review each change before adding it.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--interactive` flag for interactive staging
2. WHEN interactive mode is enabled, THE Submoduler SHALL prompt for each changed file
3. THE Submoduler SHALL display the file path and change type for each prompt
4. THE Submoduler SHALL accept y/n/q responses (yes/no/quit)
5. THE Submoduler SHALL allow quitting interactive mode at any time

### Requirement 5: Patch Mode

**User Story:** As a developer, I want to stage specific hunks within files, so that I can create focused commits with partial file changes.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--patch` flag for hunk-level staging
2. WHEN patch mode is enabled, THE Submoduler SHALL display each change hunk
3. THE Submoduler SHALL allow staging individual hunks within a file
4. THE Submoduler SHALL support splitting hunks for finer-grained control
5. THE Submoduler SHALL process each submodule sequentially in patch mode

### Requirement 6: Dry Run Mode

**User Story:** As a developer, I want to preview what would be staged without actually staging, so that I can verify the operation.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--dry-run` flag
2. WHEN dry-run mode is enabled, THE Submoduler SHALL display what would be staged
3. WHEN dry-run mode is enabled, THE Submoduler SHALL not modify the staging area
4. THE Submoduler SHALL show file counts that would be staged per submodule
5. THE Submoduler SHALL indicate which submodules would be affected

### Requirement 7: Update Tracked Files Only

**User Story:** As a developer, I want to stage only tracked files, so that I don't accidentally add untracked files.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--update` flag to stage tracked files only
2. WHEN update mode is enabled, THE Submoduler SHALL ignore untracked files
3. THE Submoduler SHALL stage modifications to tracked files
4. THE Submoduler SHALL stage deletions of tracked files
5. THE Submoduler SHALL report how many tracked files were staged

### Requirement 8: Force Add Ignored Files

**User Story:** As a developer, I want to stage files that are normally ignored, so that I can include them when necessary.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--force` flag to add ignored files
2. WHEN force mode is enabled, THE Submoduler SHALL stage files matching .gitignore patterns
3. THE Submoduler SHALL display a warning when staging ignored files
4. THE Submoduler SHALL list which ignored files were staged
5. THE Submoduler SHALL require explicit force flag for each execution

### Requirement 9: Intent to Add

**User Story:** As a developer, I want to mark untracked files as intended for tracking, so that they appear in diffs without being fully staged.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--intent-to-add` flag
2. WHEN intent-to-add is enabled, THE Submoduler SHALL mark untracked files without staging content
3. THE Submoduler SHALL allow untracked files to appear in git diff
4. THE Submoduler SHALL apply intent-to-add to all specified submodules
5. THE Submoduler SHALL report which files were marked with intent-to-add

### Requirement 10: Progress Reporting

**User Story:** As a developer, I want to see progress as files are staged, so that I know the operation is working.

#### Acceptance Criteria

1. THE Submoduler SHALL display which submodule is currently being processed
2. THE Submoduler SHALL show the count of files staged in each submodule
3. THE Submoduler SHALL display a progress indicator for large operations
4. THE Submoduler SHALL show a summary of total files staged across all submodules
5. THE Submoduler SHALL indicate when no changes were found to stage

### Requirement 11: Error Handling

**User Story:** As a developer, I want clear error messages when staging fails, so that I can resolve issues.

#### Acceptance Criteria

1. WHEN a file cannot be staged, THE Submoduler SHALL display the error message
2. THE Submoduler SHALL include the submodule name and file path in error messages
3. THE Submoduler SHALL continue processing other files after an error
4. THE Submoduler SHALL report which submodules had staging errors
5. THE Submoduler SHALL exit with code 1 when any staging operation fails

### Requirement 12: Verbose Output

**User Story:** As a developer, I want detailed output about what is being staged, so that I can verify the operation.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--verbose` flag for detailed output
2. WHEN verbose mode is enabled, THE Submoduler SHALL list each file being staged
3. THE Submoduler SHALL show the change type for each file (modified, added, deleted)
4. THE Submoduler SHALL display the full path relative to the repository root
5. THE Submoduler SHALL show git command output in verbose mode

### Requirement 13: Submodule Reference Update

**User Story:** As a developer, I want submodule reference changes staged in the parent, so that the parent tracks the new submodule state.

#### Acceptance Criteria

1. WHEN changes are staged in a submodule, THE Submoduler SHALL check if the submodule reference changed
2. IF the submodule reference changed, THEN THE Submoduler SHALL stage the reference in the parent
3. THE Submoduler SHALL indicate when submodule references are staged in the parent
4. THE Submoduler SHALL support a `--no-parent` flag to skip parent staging
5. THE Submoduler SHALL report which submodule references were updated in the parent

### Requirement 14: Ignore Removal

**User Story:** As a developer, I want to stage modifications without staging deletions, so that I can preserve removed files temporarily.

#### Acceptance Criteria

1. THE Submoduler SHALL support an `--ignore-removal` flag
2. WHEN ignore-removal is enabled, THE Submoduler SHALL stage modifications and additions only
3. THE Submoduler SHALL not stage deleted files when ignore-removal is enabled
4. THE Submoduler SHALL report how many deletions were ignored
5. THE Submoduler SHALL apply ignore-removal to all processed submodules

### Requirement 15: Exit Code Semantics

**User Story:** As a developer, I want meaningful exit codes, so that I can use the tool in scripts and CI/CD pipelines.

#### Acceptance Criteria

1. THE Submoduler SHALL exit with code 0 when all staging operations succeed
2. THE Submoduler SHALL exit with code 0 when no changes were found to stage
3. THE Submoduler SHALL exit with code 1 when any staging operation fails
4. THE Submoduler SHALL exit with code 2 when invalid arguments are provided
5. THE Submoduler SHALL exit with code 2 when not running from a git repository

# Requirements Document

## Introduction

This document specifies the requirements for the `git-status` command in the Submoduler tool. The `git-status` command provides a unified view of the git status across all submodules and the parent repository, making it easy to see what has changed throughout the entire project structure.

The command is designed to give developers a comprehensive overview of their working tree state without manually checking each submodule directory.

## Glossary

- **Submoduler**: The Ruby script tool for managing and validating git submodules
- **GitModules**: The `.gitmodules` configuration file that defines submodule mappings
- **WorkingTree**: The current state of files in the repository
- **StagingArea**: The index containing changes staged for commit
- **UncommittedChanges**: Modified, added, or deleted files not yet committed
- **UnpushedCommits**: Commits that exist locally but not on the remote
- **DirtySubmodule**: A submodule with uncommitted changes or unpushed commits
- **CleanRepository**: A repository with no uncommitted changes or unpushed commits
- **BranchStatus**: Information about the current branch and its tracking relationship

## Requirements

### Requirement 1: Submodule Status Overview

**User Story:** As a developer, I want to see the status of all submodules at once, so that I can quickly understand the state of my entire project.

#### Acceptance Criteria

1. WHEN the git-status command runs, THE Submoduler SHALL display status for all configured submodules
2. THE Submoduler SHALL show the submodule name and path for each submodule
3. THE Submoduler SHALL indicate whether each submodule is clean or has changes
4. THE Submoduler SHALL display the current branch for each submodule
5. THE Submoduler SHALL show the current commit SHA for each submodule

### Requirement 2: Uncommitted Changes Detection

**User Story:** As a developer, I want to see which submodules have uncommitted changes, so that I know where I have pending work.

#### Acceptance Criteria

1. WHEN a submodule has modified files, THE Submoduler SHALL list those files
2. WHEN a submodule has staged changes, THE Submoduler SHALL indicate this status
3. WHEN a submodule has untracked files, THE Submoduler SHALL list those files
4. THE Submoduler SHALL use visual indicators (M, A, D, ??) for file status
5. THE Submoduler SHALL group files by status type (modified, added, deleted, untracked)

### Requirement 3: Unpushed Commits Detection

**User Story:** As a developer, I want to see which submodules have unpushed commits, so that I know what needs to be pushed.

#### Acceptance Criteria

1. WHEN a submodule has commits ahead of remote, THE Submoduler SHALL display the count
2. THE Submoduler SHALL show the number of commits ahead for each submodule
3. THE Submoduler SHALL show the number of commits behind for each submodule
4. THE Submoduler SHALL indicate when a submodule has diverged from remote
5. THE Submoduler SHALL display "up to date" when a submodule matches its remote

### Requirement 4: Parent Repository Status

**User Story:** As a developer, I want to see the parent repository status alongside submodules, so that I have a complete picture.

#### Acceptance Criteria

1. THE Submoduler SHALL display the parent repository status at the top or bottom
2. THE Submoduler SHALL show uncommitted changes in the parent repository
3. THE Submoduler SHALL show unpushed commits in the parent repository
4. THE Submoduler SHALL indicate submodule reference changes in the parent
5. THE Submoduler SHALL display the current branch of the parent repository

### Requirement 5: Clean Status Reporting

**User Story:** As a developer, I want to be clearly informed when everything is clean, so that I know I'm ready to switch tasks.

#### Acceptance Criteria

1. WHEN all repositories are clean, THE Submoduler SHALL display a success message
2. THE Submoduler SHALL indicate "No uncommitted changes" when working tree is clean
3. THE Submoduler SHALL indicate "No unpushed commits" when all commits are pushed
4. THE Submoduler SHALL use green color or checkmarks for clean status
5. THE Submoduler SHALL provide a summary count of clean vs dirty repositories

### Requirement 6: Compact Display Mode

**User Story:** As a developer, I want a compact view option, so that I can quickly scan status without excessive detail.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--compact` flag for condensed output
2. WHEN compact mode is enabled, THE Submoduler SHALL show only submodules with changes
3. WHEN compact mode is enabled, THE Submoduler SHALL omit file-level details
4. THE Submoduler SHALL show summary counts (e.g., "3 modified, 2 untracked")
5. THE Submoduler SHALL indicate clean submodules with a single line in compact mode

### Requirement 7: Verbose Display Mode

**User Story:** As a developer, I want detailed status information, so that I can see exactly what has changed in each file.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--verbose` flag for detailed output
2. WHEN verbose mode is enabled, THE Submoduler SHALL show full file paths
3. WHEN verbose mode is enabled, THE Submoduler SHALL display commit messages for unpushed commits
4. THE Submoduler SHALL show the first line of each unpushed commit message
5. THE Submoduler SHALL display the author and date for unpushed commits

### Requirement 8: Branch Information Display

**User Story:** As a developer, I want to see branch information for each repository, so that I know which branches I'm working on.

#### Acceptance Criteria

1. THE Submoduler SHALL display the current branch name for each repository
2. THE Submoduler SHALL indicate when a repository is in detached HEAD state
3. THE Submoduler SHALL show the remote tracking branch for each local branch
4. THE Submoduler SHALL indicate when a branch has no remote tracking configured
5. THE Submoduler SHALL highlight when branches differ from their expected state

### Requirement 9: Color-Coded Output

**User Story:** As a developer, I want color-coded status output, so that I can quickly identify issues visually.

#### Acceptance Criteria

1. THE Submoduler SHALL use green for clean repositories and files
2. THE Submoduler SHALL use red for modified files and uncommitted changes
3. THE Submoduler SHALL use yellow for untracked files and warnings
4. THE Submoduler SHALL use blue for staged changes
5. THE Submoduler SHALL support a `--no-color` flag to disable colors

### Requirement 10: Submodule Filtering

**User Story:** As a developer, I want to check status of specific submodules, so that I can focus on relevant parts of the project.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--submodule` flag to filter by submodule name
2. THE Submoduler SHALL accept multiple `--submodule` flags
3. WHEN submodules are specified, THE Submoduler SHALL only show those submodules
4. THE Submoduler SHALL validate that specified submodules exist
5. THE Submoduler SHALL always include parent repository status regardless of filters

### Requirement 11: Porcelain Output Format

**User Story:** As a script author, I want machine-readable output, so that I can parse status programmatically.

#### Acceptance Criteria

1. THE Submoduler SHALL support a `--porcelain` flag for machine-readable output
2. WHEN porcelain mode is enabled, THE Submoduler SHALL output in a parseable format
3. THE Submoduler SHALL use consistent field separators in porcelain mode
4. THE Submoduler SHALL omit colors and decorative elements in porcelain mode
5. THE Submoduler SHALL document the porcelain output format specification

### Requirement 12: Uninitialized Submodule Detection

**User Story:** As a developer, I want to see which submodules are not initialized, so that I know what needs to be set up.

#### Acceptance Criteria

1. WHEN a submodule is not initialized, THE Submoduler SHALL indicate this status
2. THE Submoduler SHALL distinguish between uninitialized and missing submodules
3. THE Submoduler SHALL suggest running `git submodule init` for uninitialized submodules
4. THE Submoduler SHALL show which submodules are defined but not checked out
5. THE Submoduler SHALL count uninitialized submodules in the summary

### Requirement 13: Performance Optimization

**User Story:** As a developer, I want fast status checks, so that I can run the command frequently without delays.

#### Acceptance Criteria

1. THE Submoduler SHALL execute git status commands in parallel where possible
2. THE Submoduler SHALL cache git command results within a single execution
3. THE Submoduler SHALL complete status checks in under 2 seconds for typical repositories
4. THE Submoduler SHALL display results progressively as they become available
5. THE Submoduler SHALL support a `--timeout` flag to limit execution time

### Requirement 14: Summary Statistics

**User Story:** As a developer, I want summary statistics, so that I can quickly assess the overall project state.

#### Acceptance Criteria

1. THE Submoduler SHALL display a summary section at the end of output
2. THE Submoduler SHALL show total count of submodules checked
3. THE Submoduler SHALL show count of clean vs dirty submodules
4. THE Submoduler SHALL show total uncommitted files across all repositories
5. THE Submoduler SHALL show total unpushed commits across all repositories

### Requirement 15: Exit Code Semantics

**User Story:** As a developer, I want meaningful exit codes, so that I can use the tool in scripts and CI/CD pipelines.

#### Acceptance Criteria

1. THE Submoduler SHALL exit with code 0 when all repositories are clean
2. THE Submoduler SHALL exit with code 1 when any repository has uncommitted changes
3. THE Submoduler SHALL exit with code 1 when any repository has unpushed commits
4. THE Submoduler SHALL exit with code 2 when invalid arguments are provided
5. THE Submoduler SHALL exit with code 2 when not running from a git repository

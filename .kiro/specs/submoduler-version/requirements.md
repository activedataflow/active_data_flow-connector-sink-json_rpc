# Requirements Document

## Introduction

The submoduler-version feature provides version management capabilities for Ruby gems across all submodules in a monorepo. It detects version mismatches, reports current versions, and can synchronize versions across all submodules to maintain consistency.

## Glossary

- **Submoduler**: The git submodule management tool
- **Version Command**: A CLI command that manages gem versions across submodules
- **Gemspec File**: A Ruby gem specification file (*.gemspec) that contains gem metadata including version
- **Version Mismatch**: When different submodules have different gem versions
- **Synchronized Version**: All submodules using the same version number

## Requirements

### Requirement 1: Version Detection

**User Story:** As a developer, I want to see the current version of each submodule's gem, so that I can understand the version state of my monorepo

#### Acceptance Criteria

1. WHEN the user executes `submoduler.rb version`, THE Version Command SHALL display the gem name and version for each submodule
2. WHEN a submodule contains a gemspec file, THE Version Command SHALL extract the version from the gemspec
3. WHEN a submodule does not contain a gemspec file, THE Version Command SHALL report "No gemspec found"
4. THE Version Command SHALL display results in a readable table format with columns for submodule name, gem name, and version

### Requirement 2: Version Mismatch Detection

**User Story:** As a developer, I want to be notified when submodules have different versions, so that I can maintain version consistency

#### Acceptance Criteria

1. WHEN submodules have different version numbers, THE Version Command SHALL report a version mismatch
2. THE Version Command SHALL identify the highest version number among all submodules
3. WHEN displaying mismatch information, THE Version Command SHALL highlight which versions differ from the highest
4. THE Version Command SHALL exit with code 1 when version mismatches are detected
5. THE Version Command SHALL exit with code 0 when all versions match or only one version exists

### Requirement 3: Version Synchronization

**User Story:** As a developer, I want to synchronize all submodule versions to be consistent, so that I can maintain a unified version across my monorepo

#### Acceptance Criteria

1. WHEN the user executes `submoduler.rb version --sync`, THE Version Command SHALL update all submodule versions to match the highest version plus 0.0.1
2. THE Version Command SHALL update the version constant in the gem's version.rb file
3. THE Version Command SHALL preserve the existing version format (e.g., semantic versioning)
4. WHEN a version file does not exist, THE Version Command SHALL create it with the synchronized version
5. THE Version Command SHALL report which submodules had their versions updated

### Requirement 4: Dry Run Mode

**User Story:** As a developer, I want to preview version changes without applying them, so that I can verify the changes before committing

#### Acceptance Criteria

1. WHEN the user executes `submoduler.rb version --sync --dry-run`, THE Version Command SHALL display what changes would be made without modifying files
2. THE Version Command SHALL show the current version and proposed new version for each submodule
3. THE Version Command SHALL exit with code 0 in dry-run mode regardless of changes

### Requirement 5: Selective Submodule Version Management

**User Story:** As a developer, I want to check or sync versions for specific submodules only, so that I can manage versions granularly

#### Acceptance Criteria

1. WHEN the user provides `--submodule <name>` option, THE Version Command SHALL operate only on the specified submodule
2. THE Version Command SHALL support multiple `--submodule` options to target multiple specific submodules
3. WHEN specific submodules are targeted, THE Version Command SHALL only consider those submodules for mismatch detection

# Requirements Document

## Introduction

The submoduler_ini_SOT feature refactors the submoduler tool to use .submoduler.ini files as the single source of truth (SOT) for submodule configuration instead of .gitmodules. This provides better control and metadata management for submodules in the monorepo.

## Glossary

- **Submoduler**: The git submodule management tool
- **SOT (Source of Truth)**: The authoritative source for configuration data
- **INI File**: Configuration file format using sections and key-value pairs
- **Submoduler INI**: A .submoduler.ini file in each submodule containing metadata
- **Parent Repository**: The main monorepo containing all submodules
- **Submodule Entry**: Configuration data for a single submodule

## Requirements

### Requirement 1: INI File Discovery

**User Story:** As a developer, I want submoduler to discover submodules by finding .submoduler.ini files, so that configuration is decentralized

#### Acceptance Criteria

1. WHEN submoduler executes, THE system SHALL scan the repository for .submoduler.ini files
2. THE system SHALL search in common submodule directories (submodules/, examples/)
3. WHEN a .submoduler.ini file is found, THE system SHALL parse it as a submodule entry
4. THE system SHALL ignore .submoduler.ini files that are not in valid submodule locations
5. THE system SHALL report an error if no .submoduler.ini files are found

### Requirement 1a: Parent .submoduler.ini as Registry

**User Story:** As a developer, I want the parent repository to maintain a .submoduler.ini registry of submodules, so that there is a central reference that matches .gitmodules

#### Acceptance Criteria

1. THE system SHALL check for .submoduler.ini in the repository root (parent .submoduler.ini)
2. WHEN parent .submoduler.ini exists, THE system SHALL parse [submodule "name"] sections
3. THE system SHALL compare parent .submoduler.ini submodule entries with .gitmodules entries
4. WHEN entries in parent .submoduler.ini do not match .gitmodules, THE system SHALL report a mismatch
5. THE system SHALL validate that each [submodule "name"] section has path and url fields
6. THE system SHALL use parent .submoduler.ini as an additional validation source
7. WHEN parent .submoduler.ini is missing, THE system SHALL suggest creating it from .gitmodules

### Requirement 2: INI File Parsing

**User Story:** As a developer, I want .submoduler.ini files to contain all necessary metadata, so that each submodule is self-describing

#### Acceptance Criteria

1. THE system SHALL parse .submoduler.ini files using INI format
2. THE system SHALL read the [default] section for basic configuration
3. THE system SHALL read the [parent] section for parent repository information
4. WHEN a required field is missing, THE system SHALL report an error with the file path
5. THE system SHALL extract the submodule name from the directory path
6. THE system SHALL extract the submodule URL from the [parent] section

### Requirement 3: Backward Compatibility

**User Story:** As a developer, I want existing commands to work without changes, so that the migration is seamless

#### Acceptance Criteria

1. WHEN submoduler commands execute, THE system SHALL use .submoduler.ini as SOT
2. THE system SHALL maintain the same SubmoduleEntry data structure
3. THE system SHALL provide the same interface to all command classes
4. THE system SHALL not break any existing command functionality
5. THE system SHALL maintain the same exit codes and error handling

### Requirement 4: Submodule Path Detection

**User Story:** As a developer, I want submodule paths to be automatically detected, so that I don't need to configure them manually

#### Acceptance Criteria

1. WHEN a .submoduler.ini file is found, THE system SHALL determine the submodule path from its location
2. THE system SHALL calculate the relative path from the repository root
3. THE system SHALL use the directory name as the submodule name
4. THE system SHALL support nested submodule directories
5. THE system SHALL normalize paths to use forward slashes

### Requirement 5: Parent Repository Reference

**User Story:** As a developer, I want each submodule to know its parent repository, so that bidirectional relationships are maintained

#### Acceptance Criteria

1. WHEN parsing .submoduler.ini, THE system SHALL read the [parent] url field
2. THE system SHALL validate that the parent URL is a valid git repository URL
3. THE system SHALL make parent information available to commands that need it
4. WHEN the [parent] section is missing, THE system SHALL report an error
5. THE system SHALL support both HTTPS and SSH git URLs

### Requirement 6: Migration Support

**User Story:** As a developer, I want to migrate from .gitmodules to .submoduler.ini, so that I can adopt the new system

#### Acceptance Criteria

1. THE system SHALL provide a migration command to generate .submoduler.ini files from .gitmodules
2. WHEN migration runs, THE system SHALL create .submoduler.ini in each submodule directory
3. THE system SHALL populate the [parent] section with the parent repository URL
4. THE system SHALL preserve all existing submodule metadata
5. THE system SHALL report which files were created

### Requirement 7: Validation

**User Story:** As a developer, I want to validate .submoduler.ini files, so that I can catch configuration errors early

#### Acceptance Criteria

1. THE system SHALL validate that each .submoduler.ini has required sections
2. THE system SHALL validate that the [parent] url is present and valid
3. THE system SHALL report validation errors with file paths and line numbers
4. THE system SHALL validate during all command executions
5. THE system SHALL exit with code 2 for validation errors

### Requirement 8: Missing .submoduler.ini Detection

**User Story:** As a developer, I want to detect submodules missing .submoduler.ini files, so that I can ensure all submodules are properly configured

#### Acceptance Criteria

1. WHEN scanning for submodules, THE system SHALL check .gitmodules for submodule entries
2. WHEN a submodule is listed in .gitmodules, THE system SHALL verify a .submoduler.ini file exists in that path
3. WHEN a .submoduler.ini file is missing, THE system SHALL report an error with the submodule path
4. THE system SHALL list all submodules missing .submoduler.ini files
5. THE system SHALL exit with code 1 when missing .submoduler.ini files are detected

### Requirement 9: .gitignore Detection

**User Story:** As a developer, I want to detect if .submoduler.ini files are in .gitignore, so that they are not accidentally excluded from version control

#### Acceptance Criteria

1. WHEN validating, THE system SHALL check if .gitignore exists in the repository root
2. WHEN .gitignore exists, THE system SHALL check if it contains patterns matching .submoduler.ini
3. WHEN .submoduler.ini is ignored, THE system SHALL report a warning with the .gitignore pattern
4. THE system SHALL check both exact matches and wildcard patterns
5. THE system SHALL suggest removing the ignore pattern from .gitignore

### Requirement 10: Mismatch Detection

**User Story:** As a developer, I want to detect mismatches between .gitmodules and .submoduler.ini files, so that I can maintain consistency

#### Acceptance Criteria

1. WHEN both .gitmodules and .submoduler.ini exist, THE system SHALL compare their configurations
2. THE system SHALL detect when a submodule path in .gitmodules does not have a corresponding .submoduler.ini
3. THE system SHALL detect when a .submoduler.ini exists but the submodule is not in .gitmodules
4. THE system SHALL detect when the parent URL in .submoduler.ini does not match the expected parent repository
5. THE system SHALL report all mismatches with specific details about what differs
6. THE system SHALL provide suggestions for resolving each type of mismatch

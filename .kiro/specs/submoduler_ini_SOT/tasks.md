# Implementation Plan: Submoduler INI as Source of Truth

- [x] 1. Create IniFileParser utility class
  - Implement INI file format parsing (sections and key-value pairs)
  - Handle section headers [section_name]
  - Handle key-value pairs with = separator
  - Support tab-indented values
  - Return hash structure with sections and keys
  - _Requirements: 2.1_

- [x] 2. Create SubmodulerIniParser class
  - Implement file discovery to find all .submoduler.ini files
  - Search in submodules/ and examples/ directories
  - Implement exists? method to check if any INI files found
  - Implement parse method to return SubmoduleEntry array
  - Extract submodule path from .submoduler.ini file location
  - Extract submodule name from path (remove submodules/ or examples/ prefix)
  - Get git remote URL from submodule directory
  - Parse [parent] section for parent repository URL
  - Handle errors gracefully with clear error messages
  - _Requirements: 1.1, 1.2, 1.3, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.4, 5.5_

- [x] 3. Update CLI to use SubmodulerIniParser
  - Replace GitModulesParser with SubmodulerIniParser in all commands
  - Update ReportCommand to use new parser
  - Update VersionCommand to use new parser
  - Update TestCommand to use new parser
  - Update BundleCommand to use new parser
  - Update all other commands to use new parser
  - Maintain same SubmoduleEntry interface
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 4. Create MigrateCommand for .gitmodules to .submoduler.ini migration
  - Read existing .gitmodules file
  - For each submodule, create .submoduler.ini in submodule directory
  - Populate [default] section
  - Populate [parent] section with parent repository URL
  - Report which files were created
  - Handle errors if files already exist
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 5. Add validation for .submoduler.ini files
  - Validate [default] section exists
  - Validate [parent] section exists
  - Validate [parent] url field is present
  - Validate URL format is valid git URL
  - Report validation errors with file path
  - Integrate validation into SubmodulerIniParser
  - _Requirements: 2.4, 5.1, 5.2, 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 6. Test the new parser with existing submodules
  - Run all commands to verify they work with new parser
  - Test report command
  - Test version command
  - Test test command
  - Test bundle command
  - Verify same output and behavior as before
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 7. Add missing .submoduler.ini detection
  - Implement detection of submodules in .gitmodules without .submoduler.ini
  - Compare .gitmodules entries with found .submoduler.ini files
  - Report missing files with expected paths
  - Integrate into report command
  - Suggest running migrate command to fix
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 8. Add .gitignore detection
  - Check if .gitignore exists in repository root
  - Parse .gitignore for patterns matching .submoduler.ini
  - Detect exact matches and wildcard patterns (*.ini)
  - Report warnings with line numbers
  - Suggest removing ignore patterns
  - Integrate into report command
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 9. Add parent .submoduler.ini validation
  - Check for .submoduler.ini in repository root
  - Parse [submodule "name"] sections from parent .submoduler.ini
  - Compare parent .submoduler.ini entries with .gitmodules entries
  - Detect entries in parent .submoduler.ini not in .gitmodules
  - Detect entries in .gitmodules not in parent .submoduler.ini
  - Detect mismatches in path or url fields
  - Report all mismatches with specific details
  - Suggest creating parent .submoduler.ini if missing
  - Integrate into report command
  - _Requirements: 1a.1, 1a.2, 1a.3, 1a.4, 1a.5, 1a.6, 1a.7_

- [ ] 10. Add mismatch detection
  - Compare .gitmodules and child .submoduler.ini configurations
  - Detect submodules in .gitmodules but missing child .submoduler.ini
  - Detect child .submoduler.ini files not in .gitmodules
  - Detect parent URL mismatches in child .submoduler.ini files
  - Report all mismatches with specific details
  - Provide resolution suggestions for each mismatch type
  - Integrate into report command
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ] 11. Update documentation and help text
  - Update CLI help text to mention .submoduler.ini
  - Add migrate command to help text
  - Document .submoduler.ini file format
  - Update error messages to reference .submoduler.ini
  - Document validation and detection features
  - _Requirements: 1.5, 6.1_

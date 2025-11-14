# Design Document: Submoduler INI as Source of Truth

## Overview

This feature refactors the submoduler tool to use .submoduler.ini files in each submodule as the source of truth instead of the centralized .gitmodules file. This provides better decentralization and allows each submodule to be self-describing.

## Architecture

### Current Architecture
```
CLI → GitModulesParser → .gitmodules → SubmoduleEntry[]
```

### New Architecture
```
CLI → SubmodulerIniParser → .submoduler.ini files → SubmoduleEntry[]
```

## Components and Interfaces

### 1. SubmodulerIniParser (replaces GitModulesParser)

**Responsibility:** Discover and parse .submoduler.ini files

**Interface:**
```ruby
class SubmodulerIniParser
  def initialize(repo_root)
  def exists?  # Returns true if any .submoduler.ini files found
  def parse    # Returns array of SubmoduleEntry
  private
  def find_ini_files
  def parse_ini_file(file_path)
  def extract_submodule_info(file_path, ini_data)
end
```

**Key Methods:**
- `find_ini_files`: Scans repo for .submoduler.ini files
- `parse_ini_file`: Parses INI format into hash
- `extract_submodule_info`: Creates SubmoduleEntry from INI data

### 2. IniFileParser

**Responsibility:** Parse INI file format

**Interface:**
```ruby
class IniFileParser
  def self.parse(file_path)
  private
  def self.parse_content(content)
end
```

**Returns:** Hash with structure:
```ruby
{
  'default' => {},
  'parent' => {
    'url' => 'https://github.com/user/repo.git'
  }
}
```

### 3. SubmoduleEntry (existing, no changes)

The existing SubmoduleEntry class remains unchanged:
```ruby
class SubmoduleEntry
  attr_reader :name, :path, :url
  def initialize(name:, path:, url:)
end
```

## Data Models

### .submoduler.ini File Format

**Child Submodule .submoduler.ini:**
```ini
[default]

[parent]
	url = https://github.com/magenticmarketactualskill/active_data_flow.git
```

**Parent Repository .submoduler.ini (at repo root):**
```ini
[default]

[submodule "core/core"]
	path = submodules/core/core
	url = https://github.com/magenticmarketactualskill/active_data_flow-core-core.git

[submodule "runtime/heartbeat_app"]
	path = submodules/runtime/heartbeat_app
	url = https://github.com/magenticmarketactualskill/active_dataflow-runtime-heartbeat_app

[submodule "connector/active_record"]
	path = submodules/connector/active_record
	url = https://github.com/magenticmarketactualskill/active_dataflow-connector-active_record
```

### SubmoduleEntry Mapping

From .submoduler.ini location and content:
- `name`: Derived from directory name (e.g., "core/core")
- `path`: Relative path from repo root (e.g., "submodules/core/core")
- `url`: Derived from git remote in submodule directory

## Implementation Strategy

### Phase 1: Create New Parser
1. Create `SubmodulerIniParser` class
2. Create `IniFileParser` utility class
3. Implement file discovery logic
4. Implement INI parsing logic

### Phase 2: Update CLI
1. Replace `GitModulesParser` with `SubmodulerIniParser` in CLI
2. Update all command classes to use new parser
3. Maintain same interface (returns SubmoduleEntry array)

### Phase 3: Add Migration Command
1. Create `MigrateCommand` to generate .submoduler.ini files
2. Read .gitmodules
3. Create .submoduler.ini in each submodule
4. Populate [parent] section

### Phase 4: Testing
1. Test with existing submodules
2. Verify all commands work
3. Test migration command

## File Discovery Algorithm

```ruby
def find_ini_files
  ini_files = []
  
  # Check for parent .submoduler.ini first
  parent_ini = File.join(@repo_root, '.submoduler.ini')
  @parent_ini_path = parent_ini if File.exist?(parent_ini)
  
  # Search in common submodule directories
  search_paths = [
    'submodules/**/.submoduler.ini',
    'examples/**/.submoduler.ini'
  ]
  
  search_paths.each do |pattern|
    Dir.glob(File.join(@repo_root, pattern)).each do |file|
      ini_files << file
    end
  end
  
  ini_files
end

def parse_parent_ini
  return nil unless @parent_ini_path
  
  ini_data = IniFileParser.parse(@parent_ini_path)
  submodules = []
  
  ini_data.each do |section_name, section_data|
    if section_name.start_with?('submodule ')
      # Extract submodule name from section: [submodule "name"]
      name = section_name.match(/submodule "([^"]+)"/)[1]
      
      submodules << {
        name: name,
        path: section_data['path'],
        url: section_data['url']
      }
    end
  end
  
  submodules
end
```

## INI Parsing Algorithm

```ruby
def parse_ini_file(file_path)
  content = File.read(file_path)
  sections = {}
  current_section = nil
  
  content.each_line do |line|
    line = line.strip
    
    # Section header: [section_name]
    if line =~ /^\[([^\]]+)\]$/
      current_section = $1
      sections[current_section] = {}
    # Key-value pair: key = value
    elsif line =~ /^(\w+)\s*=\s*(.+)$/
      key = $1
      value = $2.strip
      sections[current_section][key] = value if current_section
    end
  end
  
  sections
end
```

## Path Extraction Algorithm

```ruby
def extract_submodule_info(file_path, ini_data)
  # Get relative path from repo root
  relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(@repo_root))
  
  # Remove .submoduler.ini from path
  submodule_path = File.dirname(relative_path)
  
  # Extract name from path (e.g., "submodules/core/core" -> "core/core")
  name = submodule_path.sub(/^(submodules|examples)\//, '')
  
  # Get URL from git remote
  url = get_git_remote_url(File.join(@repo_root, submodule_path))
  
  SubmoduleEntry.new(
    name: name,
    path: submodule_path,
    url: url
  )
end
```

## Error Handling

### No INI Files Found
```ruby
unless parser.exists?
  puts "No .submoduler.ini files found."
  puts "Run 'submoduler.rb migrate' to generate from .gitmodules"
  return 2
end
```

### Invalid INI Format
```ruby
rescue IniParseError => e
  puts "Error parsing #{file_path}: #{e.message}"
  return 2
end
```

### Missing Parent Section
```ruby
unless ini_data['parent'] && ini_data['parent']['url']
  puts "Error: #{file_path} missing [parent] url"
  return 2
end
```

## Validation and Detection

### 1. Missing .submoduler.ini Detection

**Algorithm:**
```ruby
def detect_missing_ini_files
  # Read .gitmodules
  gitmodules_parser = GitModulesParser.new(@repo_root)
  return [] unless gitmodules_parser.exists?
  
  gitmodules_entries = gitmodules_parser.parse
  missing = []
  
  gitmodules_entries.each do |entry|
    ini_path = File.join(@repo_root, entry.path, '.submoduler.ini')
    unless File.exist?(ini_path)
      missing << {
        path: entry.path,
        name: entry.name,
        expected_ini_path: ini_path
      }
    end
  end
  
  missing
end
```

**Output:**
```
⚠️  Missing .submoduler.ini files:
  ✗ submodules/core/core
    Expected: submodules/core/core/.submoduler.ini
  ✗ submodules/runtime/heartbeat_app
    Expected: submodules/runtime/heartbeat_app/.submoduler.ini

Run 'submoduler.rb migrate' to generate missing files
```

### 2. .gitignore Detection

**Algorithm:**
```ruby
def check_gitignore
  gitignore_path = File.join(@repo_root, '.gitignore')
  return nil unless File.exist?(gitignore_path)
  
  content = File.read(gitignore_path)
  patterns = []
  
  content.each_line.with_index do |line, index|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    
    # Check if pattern matches .submoduler.ini
    if line.include?('.submoduler.ini') || 
       line == '*.ini' || 
       line.match?(/\*\.ini$/)
      patterns << {
        line_number: index + 1,
        pattern: line
      }
    end
  end
  
  patterns
end
```

**Output:**
```
⚠️  .submoduler.ini files may be ignored by .gitignore:
  Line 15: *.ini
  Line 23: .submoduler.ini

These files should be tracked in version control.
Suggestion: Remove these patterns from .gitignore
```

### 3. Parent .submoduler.ini Validation

**Algorithm:**
```ruby
def validate_parent_ini_matches_gitmodules
  parent_ini_path = File.join(@repo_root, '.submoduler.ini')
  gitmodules_path = File.join(@repo_root, '.gitmodules')
  
  return { status: :no_parent_ini } unless File.exist?(parent_ini_path)
  return { status: :no_gitmodules } unless File.exist?(gitmodules_path)
  
  parent_entries = parse_parent_ini
  gitmodules_parser = GitModulesParser.new(@repo_root)
  gitmodules_entries = gitmodules_parser.parse
  
  mismatches = []
  
  # Check each entry in parent .submoduler.ini
  parent_entries.each do |parent_entry|
    gm_entry = gitmodules_entries.find { |e| e.name == parent_entry[:name] }
    
    if gm_entry.nil?
      mismatches << {
        type: :in_parent_not_gitmodules,
        name: parent_entry[:name],
        path: parent_entry[:path]
      }
    elsif gm_entry.path != parent_entry[:path] || gm_entry.url != parent_entry[:url]
      mismatches << {
        type: :mismatch,
        name: parent_entry[:name],
        parent_path: parent_entry[:path],
        gitmodules_path: gm_entry.path,
        parent_url: parent_entry[:url],
        gitmodules_url: gm_entry.url
      }
    end
  end
  
  # Check for entries in .gitmodules not in parent .submoduler.ini
  gitmodules_entries.each do |gm_entry|
    parent_entry = parent_entries.find { |e| e[:name] == gm_entry.name }
    
    if parent_entry.nil?
      mismatches << {
        type: :in_gitmodules_not_parent,
        name: gm_entry.name,
        path: gm_entry.path
      }
    end
  end
  
  { status: :validated, mismatches: mismatches }
end
```

**Output:**
```
⚠️  Parent .submoduler.ini does not match .gitmodules:

In parent .submoduler.ini but not in .gitmodules:
  ✗ experimental/feature
    Path: submodules/experimental/feature
    Suggestion: Add to .gitmodules or remove from parent .submoduler.ini

In .gitmodules but not in parent .submoduler.ini:
  ✗ core/core
    Path: submodules/core/core
    Suggestion: Add [submodule "core/core"] section to parent .submoduler.ini

Mismatched entries:
  ✗ runtime/heartbeat_app
    Path mismatch:
      Parent .submoduler.ini: submodules/runtime/heartbeat
      .gitmodules:            submodules/runtime/heartbeat_app
    Suggestion: Update parent .submoduler.ini to match .gitmodules
```

### 4. Mismatch Detection

**Algorithm:**
```ruby
def detect_mismatches
  gitmodules_parser = GitModulesParser.new(@repo_root)
  ini_parser = SubmodulerIniParser.new(@repo_root)
  
  gitmodules_entries = gitmodules_parser.exists? ? gitmodules_parser.parse : []
  ini_entries = ini_parser.exists? ? ini_parser.parse : []
  
  mismatches = {
    in_gitmodules_not_ini: [],
    in_ini_not_gitmodules: [],
    parent_url_mismatch: []
  }
  
  # Check for entries in .gitmodules but not in .submoduler.ini
  gitmodules_entries.each do |gm_entry|
    ini_entry = ini_entries.find { |ie| ie.path == gm_entry.path }
    unless ini_entry
      mismatches[:in_gitmodules_not_ini] << gm_entry
    end
  end
  
  # Check for .submoduler.ini files not in .gitmodules
  ini_entries.each do |ini_entry|
    gm_entry = gitmodules_entries.find { |ge| ge.path == ini_entry.path }
    unless gm_entry
      mismatches[:in_ini_not_gitmodules] << ini_entry
    end
  end
  
  # Check for parent URL mismatches
  ini_entries.each do |ini_entry|
    if ini_entry.parent_url != expected_parent_url
      mismatches[:parent_url_mismatch] << {
        entry: ini_entry,
        expected: expected_parent_url,
        actual: ini_entry.parent_url
      }
    end
  end
  
  mismatches
end
```

**Output:**
```
⚠️  Configuration Mismatches Detected:

In .gitmodules but missing .submoduler.ini:
  ✗ submodules/core/core
    Suggestion: Run 'submoduler.rb migrate' to create .submoduler.ini

Has .submoduler.ini but not in .gitmodules:
  ✗ submodules/experimental/feature
    Suggestion: Add to .gitmodules or remove .submoduler.ini

Parent URL mismatches:
  ✗ submodules/core/core
    Expected: https://github.com/user/active_data_flow.git
    Actual:   https://github.com/other/active_data_flow.git
    Suggestion: Update [parent] url in .submoduler.ini
```

## Migration Command

```ruby
class MigrateCommand
  def execute
    # Read .gitmodules
    parser = GitModulesParser.new(@repo_root)
    entries = parser.parse
    
    # Create .submoduler.ini in each submodule
    entries.each do |entry|
      ini_path = File.join(@repo_root, entry.path, '.submoduler.ini')
      
      content = <<~INI
        [default]
        
        [parent]
        \turl = #{parent_repo_url}
      INI
      
      File.write(ini_path, content)
      puts "Created #{ini_path}"
    end
  end
end
```

## Backward Compatibility

All existing commands continue to work because:
1. They receive the same `SubmoduleEntry[]` array
2. The interface doesn't change
3. Only the source of data changes

## Testing Strategy

### Unit Tests
1. Test INI file parsing
2. Test file discovery
3. Test path extraction
4. Test error handling

### Integration Tests
1. Test all commands with new parser
2. Test migration command
3. Test with real submodules

## Dependencies

### Existing Components
- `SubmoduleEntry`: Data structure (unchanged)
- All command classes: Use SubmoduleEntry array (unchanged)

### New Files
- `lib/submoduler/submoduler_ini_parser.rb`
- `lib/submoduler/ini_file_parser.rb`
- `lib/submoduler/migrate_command.rb`

### External Dependencies
None - uses only Ruby standard library

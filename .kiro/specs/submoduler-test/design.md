# Design Document: Submoduler Test Management

## Overview

The test management feature adds the ability to run test suites across all submodules in the monorepo. It follows the existing submoduler architecture pattern with a command class, supporting classes for test execution, and a formatter for output.

## Architecture

### Command Pattern
Following the existing pattern in submoduler, we'll create a `TestCommand` class that:
- Parses submodule entries using `GitModulesParser`
- Delegates test execution to `TestRunner`
- Uses `TestFormatter` for output display

### Component Diagram

```
CLI
 └─> TestCommand
      ├─> GitModulesParser (existing)
      ├─> TestRunner (new)
      └─> TestFormatter (new)
```

## Components and Interfaces

### 1. TestCommand
**Responsibility:** Orchestrates test execution across submodules

**Interface:**
```ruby
class TestCommand
  def initialize(repo_root, options = {})
  def execute
  private
  def run_tests(entries)
  def should_skip_submodule?(entry)
end
```

**Key Methods:**
- `execute`: Main entry point, coordinates the workflow
- `run_tests`: Executes tests for each submodule
- `should_skip_submodule?`: Determines if a submodule should be skipped

### 2. TestRunner
**Responsibility:** Executes test suite for a single submodule

**Interface:**
```ruby
class TestRunner
  def initialize(submodule_path, submodule_name, options = {})
  def run
  private
  def has_tests?
  def bundle_install
  def detect_test_command
  def execute_tests
end
```

**Returns:** Hash with structure:
```ruby
{
  submodule_name: "core/core",
  status: :passed,  # :passed, :failed, :skipped, :error
  output: "test output...",
  skip_reason: nil,  # or reason if skipped
  duration: 2.5  # seconds
}
```

**Test Detection Logic:**
- Check for `spec` directory (RSpec)
- Check for `test` directory (Minitest)
- Skip if neither exists

**Test Command Detection:**
- Try `bundle exec rspec` if Gemfile exists
- Try `rspec` if no Gemfile
- Try `rake spec` as fallback

### 3. TestFormatter
**Responsibility:** Formats test results for console output

**Interface:**
```ruby
class TestFormatter
  def initialize(test_results, options = {})
  def format
  private
  def format_header
  def format_results_table
  def format_failure_details
  def format_summary
end
```

**Output Formats:**
- Table view: submodule name | status | duration
- Failure details with output for failed tests
- Summary showing pass/fail/skip counts

## Data Models

### TestResult Structure
```ruby
{
  submodule_name: "core/core",
  status: :passed,
  output: "...\n32 examples, 0 failures\n...",
  skip_reason: nil,
  duration: 2.5,
  error: nil
}
```

### Status Values
- `:passed` - All tests passed
- `:failed` - One or more tests failed
- `:skipped` - Tests were skipped (no tests, not initialized, etc.)
- `:error` - Error running tests (command not found, etc.)

## Error Handling

### No Tests Found
- Return status: `:skipped`
- Skip reason: "No tests found"
- Don't count as failure

### Submodule Not Initialized
- Return status: `:skipped`
- Skip reason: "Not initialized"
- Don't count as failure

### Bundle Install Fails
- Return status: `:error`
- Include error message
- Count as failure

### Test Command Not Found
- Return status: `:error`
- Include error message
- Count as failure

### Test Execution Fails
- Return status: `:failed`
- Capture full output
- Count as failure

## Testing Strategy

### Unit Tests
1. **TestRunner**
   - Test test directory detection
   - Test command detection logic
   - Test bundle install execution
   - Test output capture

2. **TestFormatter**
   - Test table formatting
   - Test failure output display
   - Test summary calculations
   - Test color output

### Integration Tests
1. Test full test execution across multiple submodules
2. Test --submodule filtering
3. Test --verbose mode
4. Test exit codes for various scenarios

## Implementation Notes

### Test Directory Detection
Check for these directories in order:
1. `spec/` - RSpec convention
2. `test/` - Minitest convention

### Bundle Install Strategy
- Only run if Gemfile exists
- Run in submodule directory
- Capture output for debugging
- Fail fast if bundle install fails

### Test Command Selection
Priority order:
1. `bundle exec rspec` (if Gemfile exists)
2. `rspec` (if rspec is available)
3. `rake spec` (fallback)

### Output Capture
- Capture both stdout and stderr
- In verbose mode, stream output in real-time
- In normal mode, only show output for failures

### Verbose Mode
When `--verbose` is enabled:
- Stream test output in real-time
- Show bundle install output
- Show full command being executed

## CLI Integration

### New Command
Add to CLI.rb:
```ruby
when 'test'
  TestCommand.new(@repo_root, options).execute
```

### Help Text Addition
```
test                    Run tests across submodules

Test Options:
  --verbose, -v           Show detailed test output
  --submodule <name>      Test specific submodule(s)
```

## Dependencies

### Existing Components
- `GitModulesParser`: Parse .gitmodules file
- `SubmoduleEntry`: Submodule data structure
- `GitExecutor`: Execute commands (can be reused)
- CLI option parsing infrastructure

### New Files
- `lib/submoduler/test_command.rb`
- `lib/submoduler/test_runner.rb`
- `lib/submoduler/test_formatter.rb`

### External Dependencies
None - uses only Ruby standard library
Assumes test frameworks (rspec, minitest) are in submodule Gemfiles

# frozen_string_literal: true

require_relative 'version_command'
require_relative 'git_add_command'
require_relative 'git_commit_command'
require_relative 'test_command'
require_relative 'push_command'

module Submoduler
  # Orchestrates the complete release workflow
  class ReleaseCommand
    def initialize(repo_root, options = {})
      @repo_root = repo_root
      @options = options
      @steps_completed = []
    end

    def execute
      puts "━" * 80
      puts "Submoduler Release Workflow"
      puts "━" * 80
      puts ""

      # Step 0: Validate message
      return 2 unless validate_message

      # Step 1: Sync versions
      return 1 unless sync_versions

      # Step 2: Commit changes
      return 1 unless commit_changes

      # Step 3: Run tests
      return 1 unless run_tests

      # Step 4: Push changes
      return 1 unless push_changes

      puts ""
      puts colorize("✓ Release completed successfully!", :green)
      puts ""
      0

    rescue StandardError => e
      puts ""
      puts colorize("✗ Release failed: #{e.message}", :red)
      puts e.backtrace if ENV['DEBUG']
      2
    end

    private

    def validate_message
      unless @options[:message] && !@options[:message].empty?
        puts colorize("✗ Error: Release message is required. Use -m or --message option", :red)
        puts ""
        return false
      end

      puts colorize("✓ Release message: \"#{@options[:message]}\"", :green)
      puts ""
      @steps_completed << :validate
      true
    end

    def sync_versions
      puts colorize("Step 1: Synchronizing versions...", :blue)
      puts ""

      version_options = @options.dup
      version_options[:sync] = true

      version_cmd = VersionCommand.new(@repo_root, version_options)
      exit_code = version_cmd.execute

      if exit_code == 0
        puts ""
        puts colorize("✓ Versions synchronized", :green)
        puts ""
        @steps_completed << :sync
        true
      else
        puts ""
        puts colorize("✗ Version synchronization failed", :red)
        false
      end
    end

    def commit_changes
      puts colorize("Step 2: Committing changes...", :blue)
      puts ""

      # Stage all changes
      add_options = @options.dup
      add_options[:all] = true

      add_cmd = GitAddCommand.new(@repo_root, add_options)
      exit_code = add_cmd.execute

      if exit_code != 0
        puts ""
        puts colorize("✗ Failed to stage changes", :red)
        return false
      end

      # Commit changes
      commit_options = @options.dup
      commit_cmd = GitCommitCommand.new(@repo_root, commit_options)
      exit_code = commit_cmd.execute

      if exit_code == 0
        puts ""
        puts colorize("✓ Changes committed", :green)
        puts ""
        @steps_completed << :commit
        true
      else
        puts ""
        puts colorize("✗ Commit failed", :red)
        false
      end
    end

    def run_tests
      puts colorize("Step 3: Running tests...", :blue)
      puts ""

      test_cmd = TestCommand.new(@repo_root, @options)
      exit_code = test_cmd.execute

      if exit_code == 0
        puts ""
        puts colorize("✓ All tests passed", :green)
        puts ""
        @steps_completed << :test
        true
      else
        puts ""
        puts colorize("✗ Tests failed", :red)
        puts ""
        show_rollback_instructions
        false
      end
    end

    def push_changes
      puts colorize("Step 4: Pushing changes...", :blue)
      puts ""

      push_cmd = PushCommand.new(@repo_root, @options)
      exit_code = push_cmd.execute

      if exit_code == 0
        puts ""
        puts colorize("✓ Changes pushed", :green)
        @steps_completed << :push
        true
      else
        puts ""
        puts colorize("✗ Push failed", :red)
        false
      end
    end

    def show_rollback_instructions
      puts colorize("Commits created but not pushed.", :yellow)
      puts ""
      puts "To rollback commits:"
      puts "  cd <submodule> && git reset --soft HEAD~1  # For each submodule"
      puts "  git reset --soft HEAD~1                     # In parent repository"
      puts ""
      puts "Or fix the issues and run:"
      puts "  submoduler.rb test   # Verify tests pass"
      puts "  submoduler.rb push   # Push the commits"
      puts ""
    end

    def colorize(text, color)
      return text if @options[:no_color]

      colors = {
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        blue: "\e[34m",
        reset: "\e[0m"
      }

      "#{colors[color]}#{text}#{colors[:reset]}"
    end
  end
end

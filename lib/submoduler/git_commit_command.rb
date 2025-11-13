# frozen_string_literal: true

require_relative 'base_command'
require_relative 'git_executor'
require_relative 'output_formatter'

module Submoduler
  # Commits staged changes across submodules
  class GitCommitCommand < BaseCommand
    def execute
      formatter = OutputFormatter.new(no_color: @options[:no_color])
      message = @options[:message]
      
      unless message
        puts formatter.failure("Commit message required. Use -m flag.")
        return 2
      end
      
      puts formatter.header("Committing Changes#{dry_run? ? ' (Dry Run)' : ''}")
      
      committed_count = 0
      
      # Commit each submodule
      filtered_submodules.each do |entry|
        submodule_path = File.join(@repo_root, entry.path)
        next unless File.exist?(submodule_path)
        
        if commit_repository(submodule_path, entry.name, message, formatter)
          committed_count += 1
        end
      end
      
      # Commit parent repository
      if commit_repository(@repo_root, 'Parent Repository', message, formatter)
        committed_count += 1
      end
      
      if committed_count == 0
        puts "\n#{formatter.info('No changes to commit')}"
      else
        puts "\n#{formatter.success("Committed #{committed_count} repositories")}"
      end
      
      0
    end

    private

    def commit_repository(path, name, message, formatter)
      executor = GitExecutor.new(path)
      
      # Check for staged changes
      result = executor.execute('git diff --cached --quiet')
      return false if result[:success] # No staged changes
      
      puts "\n#{formatter.info("Committing #{name}")}"
      
      if dry_run?
        puts "  Would commit with message: #{message}"
        return true
      end
      
      # Build commit command
      command = build_commit_command(message)
      result = executor.execute(command, capture_output: true)
      
      if result[:success]
        # Get commit SHA
        sha_result = executor.execute('git rev-parse --short HEAD')
        sha = sha_result[:output]
        
        puts formatter.success("Committed as #{sha}")
        puts "  #{message}" if verbose?
        true
      else
        puts formatter.failure("Failed to commit")
        puts result[:output] if result[:output]
        false
      end
    end

    def build_commit_command(message)
      cmd = 'git commit'
      cmd += ' --all' if @options[:all]
      cmd += ' --amend' if @options[:amend]
      cmd += ' --allow-empty' if @options[:allow_empty]
      cmd += ' --no-verify' if @options[:no_verify]
      cmd += " --gpg-sign#{@options[:gpg_sign] == true ? '' : "=#{@options[:gpg_sign]}"}" if @options[:gpg_sign]
      cmd += " --author='#{@options[:author]}'" if @options[:author]
      cmd += " --date='#{@options[:date]}'" if @options[:date]
      cmd += ' --verbose' if verbose?
      cmd += " -m '#{message.gsub("'", "'\\''")}'"
      cmd
    end
  end
end

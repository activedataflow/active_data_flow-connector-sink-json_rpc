# frozen_string_literal: true

require_relative 'base_command'
require_relative 'repo_status_checker'
require_relative 'git_executor'
require_relative 'output_formatter'

module Submoduler
  # Pushes changes from submodules and parent repository
  class PushCommand < BaseCommand
    def execute
      formatter = OutputFormatter.new(no_color: @options[:no_color])
      remote = @options[:remote] || 'origin'
      
      puts formatter.header("Pushing Submodules#{dry_run? ? ' (Dry Run)' : ''}")
      
      # Find submodules with unpushed commits
      modified_submodules = find_modified_submodules
      
      if modified_submodules.empty?
        puts formatter.success("No submodules have unpushed commits")
        return check_and_push_parent(formatter, remote)
      end
      
      # Push each submodule
      modified_submodules.each_with_index do |entry, index|
        puts "\n#{formatter.info("Pushing submodule #{index + 1}/#{modified_submodules.size}: #{entry[:name]}")}"
        
        result = push_repository(entry[:path], entry[:branch], remote, formatter)
        return 1 unless result
      end
      
      # Push parent repository
      check_and_push_parent(formatter, remote)
    end

    private

    def find_modified_submodules
      modified = []
      
      filtered_submodules.each do |entry|
        submodule_path = File.join(@repo_root, entry.path)
        next unless File.exist?(submodule_path)
        
        checker = RepoStatusChecker.new(submodule_path, name: entry.name)
        status = checker.check
        
        next unless status.is_initialized && status.has_unpushed?
        
        if status.has_uncommitted?
          puts OutputFormatter.new.warning("#{entry.name} has uncommitted changes")
        end
        
        modified << {
          name: entry.name,
          path: submodule_path,
          branch: status.branch,
          commits: status.commits_ahead
        }
      end
      
      modified
    end

    def check_and_push_parent(formatter, remote)
      checker = RepoStatusChecker.new(@repo_root, name: 'Parent')
      status = checker.check
      
      if status.has_unpushed?
        puts "\n#{formatter.info('Pushing parent repository')}"
        result = push_repository(@repo_root, status.branch, remote, formatter)
        return result ? 0 : 1
      else
        puts "\n#{formatter.success('Parent repository is up to date')}"
        0
      end
    end

    def push_repository(path, branch, remote, formatter)
      executor = GitExecutor.new(path)
      
      # Check remote exists
      unless executor.remote_exists?(remote)
        puts formatter.failure("Remote '#{remote}' not found")
        return false
      end
      
      # Check tracking
      unless executor.remote_tracking_branch
        puts formatter.warning("No remote tracking branch configured")
        puts "  Suggestion: git branch --set-upstream-to=#{remote}/#{branch} #{branch}"
        return true # Don't fail, just skip
      end
      
      if dry_run?
        puts formatter.info("Would push #{branch} to #{remote}")
        return true
      end
      
      # Execute push
      force_flag = @options[:force] ? ' --force' : ''
      result = executor.execute("git push #{remote} #{branch}#{force_flag}", capture_output: false)
      
      if result[:success]
        puts formatter.success("Successfully pushed to #{remote}/#{branch}")
        true
      else
        puts formatter.failure("Failed to push")
        puts result[:output] if result[:output]
        false
      end
    end
  end
end

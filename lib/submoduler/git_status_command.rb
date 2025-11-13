# frozen_string_literal: true

require_relative 'base_command'
require_relative 'repo_status_checker'
require_relative 'output_formatter'

module Submoduler
  # Displays git status across all submodules
  class GitStatusCommand < BaseCommand
    def execute
      statuses = collect_statuses
      display_statuses(statuses)
      
      # Exit code: 0 if all clean, 1 if any dirty
      statuses.all?(&:clean?) ? 0 : 1
    end

    private

    def collect_statuses
      statuses = []
      
      # Collect parent repository status
      statuses << check_parent_status
      
      # Collect submodule statuses
      filtered_submodules.each do |entry|
        statuses << check_submodule_status(entry)
      end
      
      statuses
    end

    def check_parent_status
      checker = RepoStatusChecker.new(@repo_root, name: 'Parent Repository')
      checker.check
    end

    def check_submodule_status(entry)
      submodule_path = File.join(@repo_root, entry.path)
      checker = RepoStatusChecker.new(submodule_path, name: entry.name)
      checker.check
    end

    def display_statuses(statuses)
      formatter = OutputFormatter.new(no_color: @options[:no_color])
      
      if @options[:porcelain]
        display_porcelain(statuses)
      elsif @options[:compact]
        display_compact(statuses, formatter)
      elsif @options[:verbose]
        display_verbose(statuses, formatter)
      else
        display_normal(statuses, formatter)
      end
      
      display_summary(statuses, formatter) unless @options[:porcelain]
    end

    def display_normal(statuses, formatter)
      puts formatter.header("Submodule Status Report")
      
      statuses.each do |status|
        display_repo_status(status, formatter)
      end
    end

    def display_compact(statuses, formatter)
      statuses.each do |status|
        next if status.clean? && !verbose?
        
        symbol = status.clean? ? formatter.success('') : formatter.failure('')
        details = []
        details << "#{status.uncommitted_files.size} uncommitted" if status.has_uncommitted?
        details << "#{status.commits_ahead} ahead" if status.has_unpushed?
        
        detail_str = details.empty? ? '' : " - #{details.join(', ')}"
        puts "#{symbol} #{status.name} (#{status.branch})#{detail_str}"
      end
    end

    def display_verbose(statuses, formatter)
      puts formatter.header("Submodule Status Report (Verbose)")
      
      statuses.each do |status|
        puts formatter.section("📦 #{status.name}")
        puts "  Branch: #{status.branch || 'N/A'}"
        puts "  Remote: #{status.remote_branch || 'No tracking'}"
        puts "  Path: #{status.path}"
        
        if status.has_uncommitted?
          puts "\n  Uncommitted Changes:"
          status.uncommitted_files.each do |file|
            puts "    #{file[:status]} #{file[:path]}"
          end
        end
        
        if status.has_unpushed?
          puts "\n  #{formatter.warning("#{status.commits_ahead} commits ahead of remote")}"
        end
        
        if status.clean?
          puts "\n  #{formatter.success('Clean - No changes')}"
        end
        
        puts ""
      end
    end

    def display_porcelain(statuses)
      statuses.each do |status|
        uncommitted = status.uncommitted_files.size
        ahead = status.commits_ahead
        behind = status.commits_behind
        branch = status.branch || ''
        remote = status.remote_branch || ''
        
        puts "#{status.name}|#{branch}|#{remote}|#{uncommitted}|#{ahead}|#{behind}"
      end
    end

    def display_repo_status(status, formatter)
      puts formatter.section("📦 #{status.name} (#{status.branch || 'detached'})")
      
      unless status.is_initialized
        puts "  #{formatter.warning('Not initialized')}"
        return
      end
      
      if status.has_uncommitted?
        puts "  #{formatter.failure("#{status.uncommitted_files.size} uncommitted files:")}"
        status.uncommitted_files.first(5).each do |file|
          puts "    #{file[:status]} #{file[:path]}"
        end
        puts "    ... and #{status.uncommitted_files.size - 5} more" if status.uncommitted_files.size > 5
      end
      
      if status.has_unpushed?
        puts "  #{formatter.warning("#{status.commits_ahead} commits ahead of #{status.remote_branch}")}"
      end
      
      unless status.tracking_configured?
        puts "  #{formatter.warning('No remote tracking configured')}"
      end
      
      if status.clean?
        puts "  #{formatter.success('Clean - No uncommitted changes')}"
        puts "  #{formatter.success('Up to date with remote')}" if status.tracking_configured?
      end
    end

    def display_summary(statuses, formatter)
      clean_count = statuses.count(&:clean?)
      dirty_count = statuses.count(&:dirty?)
      total_uncommitted = statuses.sum { |s| s.uncommitted_files.size }
      total_unpushed = statuses.sum(&:commits_ahead)
      
      puts formatter.header("Summary")
      puts "Total repositories: #{statuses.size}"
      puts "Clean: #{formatter.colorize(clean_count.to_s, :green)}, Dirty: #{formatter.colorize(dirty_count.to_s, :red)}"
      puts "Total uncommitted files: #{total_uncommitted}" if total_uncommitted > 0
      puts "Total unpushed commits: #{total_unpushed}" if total_unpushed > 0
    end
  end
end

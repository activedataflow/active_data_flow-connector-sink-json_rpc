# frozen_string_literal: true

require_relative 'base_command'
require_relative 'git_executor'
require_relative 'output_formatter'

module Submoduler
  # Stages changes across submodules
  class GitAddCommand < BaseCommand
    def execute
      formatter = OutputFormatter.new(no_color: @options[:no_color])
      patterns = @options[:patterns] || ['.']
      
      puts formatter.header("Staging Changes#{dry_run? ? ' (Dry Run)' : ''}")
      
      total_staged = 0
      
      # Stage in each submodule
      filtered_submodules.each do |entry|
        submodule_path = File.join(@repo_root, entry.path)
        next unless File.exist?(submodule_path)
        
        count = stage_in_repository(submodule_path, entry.name, patterns, formatter)
        total_staged += count if count
      end
      
      # Update parent repository submodule references
      unless @options[:no_parent]
        update_parent_references(formatter)
      end
      
      puts "\n#{formatter.success("Total files staged: #{total_staged}")}"
      0
    end

    private

    def stage_in_repository(path, name, patterns, formatter)
      executor = GitExecutor.new(path)
      
      # Check for changes
      return 0 unless executor.has_uncommitted_changes?
      
      puts "\n#{formatter.info("Staging in #{name}")}"
      
      if dry_run?
        files = executor.uncommitted_files
        puts "  Would stage #{files.size} files"
        return files.size
      end
      
      # Build git add command
      command = build_add_command(patterns)
      result = executor.execute(command, capture_output: true)
      
      if result[:success]
        files = executor.uncommitted_files.select { |f| f[:status].start_with?('A', 'M', 'D') }
        puts formatter.success("Staged #{files.size} files") if verbose?
        files.size
      else
        puts formatter.failure("Failed to stage files")
        puts result[:output] if result[:output]
        0
      end
    end

    def build_add_command(patterns)
      cmd = 'git add'
      cmd += ' --all' if @options[:all]
      cmd += ' --update' if @options[:update]
      cmd += ' --force' if @options[:force]
      cmd += ' --intent-to-add' if @options[:intent_to_add]
      cmd += ' --patch' if @options[:patch]
      cmd += ' --interactive' if @options[:interactive]
      cmd += ' --ignore-removal' if @options[:ignore_removal]
      cmd += ' --verbose' if verbose?
      cmd += " #{patterns.join(' ')}"
      cmd
    end

    def update_parent_references(formatter)
      executor = GitExecutor.new(@repo_root)
      
      # Check if any submodule references changed
      result = executor.execute('git status --porcelain')
      return unless result[:success]
      
      submodule_changes = result[:output].lines.select { |line| line.include?('submodules/') }
      return if submodule_changes.empty?
      
      puts "\n#{formatter.info('Updating submodule references in parent')}"
      
      if dry_run?
        puts "  Would stage #{submodule_changes.size} submodule reference(s)"
        return
      end
      
      # Stage submodule references
      filtered_submodules.each do |entry|
        executor.execute("git add #{entry.path}")
      end
      
      puts formatter.success("Staged submodule references")
    end
  end
end

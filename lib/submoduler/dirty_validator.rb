# frozen_string_literal: true

require_relative 'validation_result'
require_relative 'repo_status_checker'

module Submoduler
  # Validates that submodules have no uncommitted changes
  class DirtyValidator
    def initialize(repo_root, entries)
      @repo_root = repo_root
      @entries = entries
    end

    def validate
      @entries.map do |entry|
        check_dirty_status(entry)
      end
    end

    private

    def check_dirty_status(entry)
      path = File.join(@repo_root, entry.path)
      
      # Skip if not initialized
      unless File.exist?(File.join(path, '.git'))
        return ValidationResult.new(
          submodule_name: entry.name,
          check_type: :dirty,
          status: :pass
        )
      end

      # Check for uncommitted changes
      checker = RepoStatusChecker.new(path, name: entry.name)
      status = checker.check
      
      if status.uncommitted_files.empty?
        ValidationResult.new(
          submodule_name: entry.name,
          check_type: :dirty,
          status: :pass
        )
      else
        # Format the list of changed files
        files_list = status.uncommitted_files.map { |f| "#{f[:status]} #{f[:path]}" }.join("\n    ")
        ValidationResult.new(
          submodule_name: entry.name,
          check_type: :dirty,
          status: :fail,
          message: "Uncommitted changes:\n    #{files_list}"
        )
      end
    end
  end
end

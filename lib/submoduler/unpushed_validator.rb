# frozen_string_literal: true

require_relative 'validation_result'
require_relative 'repo_status_checker'

module Submoduler
  # Validates that submodules have no unpushed commits
  class UnpushedValidator
    def initialize(repo_root, entries)
      @repo_root = repo_root
      @entries = entries
    end

    def validate
      @entries.map do |entry|
        check_unpushed_status(entry)
      end
    end

    private

    def check_unpushed_status(entry)
      path = File.join(@repo_root, entry.path)
      
      # Skip if not initialized
      unless File.exist?(File.join(path, '.git'))
        return ValidationResult.new(
          submodule_name: entry.name,
          check_type: :unpushed,
          status: :pass
        )
      end

      # Check for unpushed commits
      checker = RepoStatusChecker.new(path, name: entry.name)
      status = checker.check
      
      if status.commits_ahead == 0
        ValidationResult.new(
          submodule_name: entry.name,
          check_type: :unpushed,
          status: :pass
        )
      else
        commit_word = status.commits_ahead == 1 ? 'commit' : 'commits'
        ValidationResult.new(
          submodule_name: entry.name,
          check_type: :unpushed,
          status: :fail,
          message: "#{status.commits_ahead} unpushed #{commit_word}"
        )
      end
    end
  end
end

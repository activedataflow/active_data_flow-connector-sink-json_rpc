# frozen_string_literal: true

module Submoduler
  # Represents the status of a repository
  class RepoStatus
    attr_reader :name, :path, :branch, :remote_branch, :uncommitted_files,
                :commits_ahead, :commits_behind, :is_initialized, :is_detached

    def initialize(name:, path:, branch: nil, remote_branch: nil, 
                   uncommitted_files: [], commits_ahead: 0, commits_behind: 0,
                   is_initialized: true, is_detached: false)
      @name = name
      @path = path
      @branch = branch
      @remote_branch = remote_branch
      @uncommitted_files = uncommitted_files
      @commits_ahead = commits_ahead
      @commits_behind = commits_behind
      @is_initialized = is_initialized
      @is_detached = is_detached
    end

    def clean?
      uncommitted_files.empty? && commits_ahead == 0
    end

    def dirty?
      !clean?
    end

    def has_uncommitted?
      !uncommitted_files.empty?
    end

    def has_unpushed?
      commits_ahead > 0
    end

    def tracking_configured?
      !remote_branch.nil?
    end
  end
end

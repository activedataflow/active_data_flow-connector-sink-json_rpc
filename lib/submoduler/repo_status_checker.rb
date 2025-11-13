# frozen_string_literal: true

require_relative 'repo_status'
require_relative 'git_executor'

module Submoduler
  # Checks the status of a single repository
  class RepoStatusChecker
    def initialize(path, name: nil)
      @path = path
      @name = name || File.basename(path)
      @executor = GitExecutor.new(path)
    end

    def check
      return uninitialized_status unless initialized?

      RepoStatus.new(
        name: @name,
        path: @path,
        branch: @executor.current_branch,
        remote_branch: @executor.remote_tracking_branch,
        uncommitted_files: @executor.uncommitted_files,
        commits_ahead: @executor.commits_ahead_behind[:ahead],
        commits_behind: @executor.commits_ahead_behind[:behind],
        is_initialized: true,
        is_detached: @executor.detached_head?
      )
    rescue => e
      error_status(e.message)
    end

    private

    def initialized?
      File.exist?(File.join(@path, '.git'))
    end

    def uninitialized_status
      RepoStatus.new(
        name: @name,
        path: @path,
        is_initialized: false
      )
    end

    def error_status(error_message)
      RepoStatus.new(
        name: @name,
        path: @path,
        is_initialized: false
      )
    end
  end
end

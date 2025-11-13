# frozen_string_literal: true

module Submoduler
  # Executes git commands in repositories
  class GitExecutor
    def initialize(path)
      @path = path
    end

    def execute(command, capture_output: true)
      Dir.chdir(@path) do
        if capture_output
          output = `#{command} 2>&1`
          success = $?.success?
          { success: success, output: output.strip, exit_code: $?.exitstatus }
        else
          system(command)
          { success: $?.success?, exit_code: $?.exitstatus }
        end
      end
    rescue => e
      { success: false, output: e.message, exit_code: 1, error: e }
    end

    def current_branch
      result = execute('git branch --show-current')
      result[:success] ? result[:output] : nil
    end

    def remote_tracking_branch
      result = execute('git rev-parse --abbrev-ref @{u}')
      result[:success] ? result[:output] : nil
    end

    def commits_ahead_behind
      result = execute('git rev-list --left-right --count @{u}...HEAD')
      return { ahead: 0, behind: 0 } unless result[:success]
      
      behind, ahead = result[:output].split("\t").map(&:to_i)
      { ahead: ahead || 0, behind: behind || 0 }
    end

    def unpushed_commit_count
      result = execute('git rev-list @{u}..HEAD --count')
      result[:success] ? result[:output].to_i : 0
    end

    def has_uncommitted_changes?
      result = execute('git status --porcelain')
      result[:success] && !result[:output].empty?
    end

    def uncommitted_files
      result = execute('git status --porcelain')
      return [] unless result[:success]
      
      result[:output].lines.map do |line|
        status = line[0..1]
        path = line[3..-1].strip
        { status: status, path: path }
      end
    end

    def detached_head?
      result = execute('git symbolic-ref -q HEAD')
      !result[:success]
    end

    def remote_exists?(remote = 'origin')
      result = execute("git remote get-url #{remote}")
      result[:success]
    end
  end
end

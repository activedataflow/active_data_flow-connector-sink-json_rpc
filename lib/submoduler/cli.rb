# frozen_string_literal: true

require_relative 'report_command'
require_relative 'git_status_command'
require_relative 'push_command'
require_relative 'git_add_command'
require_relative 'git_commit_command'

module Submoduler
  # Command line interface for submoduler tool
  class CLI
    def self.run(args)
      new(args).run
    end

    def initialize(args)
      @args = args
      @repo_root = Dir.pwd
    end

    def run
      # Check for help flag
      if @args.include?('--help') || @args.include?('-h')
        show_usage
        return 0
      end

      # Verify we're in a git repository
      unless git_repository?
        puts "Error: Not a git repository"
        puts "Please run this command from the root of a git repository"
        return 2
      end

      # Parse command and options
      command, options = parse_command_and_options(@args)

      case command
      when 'report'
        ReportCommand.new(@repo_root).execute
      when 'git-status', 'status'
        GitStatusCommand.new(@repo_root, options).execute
      when 'push'
        PushCommand.new(@repo_root, options).execute
      when 'git-add', 'add'
        GitAddCommand.new(@repo_root, options).execute
      when 'git-commit', 'commit'
        GitCommitCommand.new(@repo_root, options).execute
      when nil
        show_usage
        0
      else
        puts "Error: Unknown command '#{command}'"
        puts ""
        show_usage
        2
      end
    rescue StandardError => e
      puts "Fatal error: #{e.message}"
      puts e.backtrace if ENV['DEBUG']
      2
    end

    private

    def parse_command_and_options(args)
      return [nil, {}] if args.empty?
      
      command = args.first
      options = {}
      
      i = 1
      while i < args.length
        arg = args[i]
        
        case arg
        when '--dry-run'
          options[:dry_run] = true
        when '--verbose', '-v'
          options[:verbose] = true
        when '--compact'
          options[:compact] = true
        when '--porcelain'
          options[:porcelain] = true
        when '--no-color'
          options[:no_color] = true
        when '--force', '-f'
          options[:force] = true
        when '--all', '-a'
          options[:all] = true
        when '--update', '-u'
          options[:update] = true
        when '--patch', '-p'
          options[:patch] = true
        when '--interactive', '-i'
          options[:interactive] = true
        when '--intent-to-add', '-N'
          options[:intent_to_add] = true
        when '--ignore-removal'
          options[:ignore_removal] = true
        when '--amend'
          options[:amend] = true
        when '--allow-empty'
          options[:allow_empty] = true
        when '--no-verify'
          options[:no_verify] = true
        when '--no-parent'
          options[:no_parent] = true
        when '--remote'
          options[:remote] = args[i + 1]
          i += 1
        when '--submodule'
          options[:submodules] ||= []
          options[:submodules] << args[i + 1]
          i += 1
        when '-m', '--message'
          options[:message] = args[i + 1]
          i += 1
        when '--author'
          options[:author] = args[i + 1]
          i += 1
        when '--date'
          options[:date] = args[i + 1]
          i += 1
        when /^--gpg-sign(?:=(.+))?$/
          options[:gpg_sign] = $1 || true
        else
          # Treat as pattern for git-add
          options[:patterns] ||= []
          options[:patterns] << arg
        end
        
        i += 1
      end
      
      [command, options]
    end

    def git_repository?
      File.directory?(File.join(@repo_root, '.git'))
    end

    def show_usage
      puts <<~USAGE
        Submoduler - Git Submodule Management Tool

        Usage:
          submoduler.rb <command> [options]

        Commands:
          report                  Validate submodule configuration
          git-status, status      Show status across all submodules
          push                    Push submodules and parent repository
          git-add, add            Stage changes across submodules
          git-commit, commit      Commit changes across submodules

        Common Options:
          --help, -h              Show this help message
          --verbose, -v           Show detailed output
          --dry-run               Preview without executing
          --submodule <name>      Operate on specific submodule(s)

        Status Options:
          --compact               Show only dirty repositories
          --porcelain             Machine-readable output
          --no-color              Disable colored output

        Push Options:
          --remote <name>         Push to specific remote (default: origin)
          --force, -f             Force push

        Add Options:
          --all, -a               Stage all changes
          --update, -u            Stage tracked files only
          --patch, -p             Interactive patch mode
          --force, -f             Add ignored files
          --no-parent             Don't update parent references

        Commit Options:
          -m, --message <msg>     Commit message
          --amend                 Amend last commit
          --all, -a               Commit all changes
          --gpg-sign[=<key>]      Sign commits with GPG
          --no-verify             Skip commit hooks

        Examples:
          submoduler.rb report
          submoduler.rb status --compact
          submoduler.rb push --dry-run
          submoduler.rb add --all
          submoduler.rb commit -m "Update submodules"
          submoduler.rb push --submodule core_gem/core

        Exit Codes:
          0 - Success
          1 - Validation/operation failures
          2 - Script error (not a git repo, invalid arguments)
      USAGE
    end
  end
end

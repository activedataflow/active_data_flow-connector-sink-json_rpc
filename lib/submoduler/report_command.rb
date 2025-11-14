# frozen_string_literal: true

require_relative 'submoduler_ini_parser'
require_relative 'path_validator'
require_relative 'init_validator'
require_relative 'dirty_validator'
require_relative 'unpushed_validator'
require_relative 'report_formatter'

module Submoduler
  # Orchestrates validation checks and generates report
  class ReportCommand
    def initialize(repo_root)
      @repo_root = repo_root
    end

    def execute
      parser = SubmodulerIniParser.new(@repo_root)

      # Check if .submoduler.ini files exist
      unless parser.exists?
        puts "No .submoduler.ini files found. No submodules configured."
        puts "Run 'submoduler.rb migrate' to generate from .gitmodules"
        return 0
      end

      # Parse submodule entries
      begin
        entries = parser.parse
      rescue StandardError => e
        puts "Error parsing .gitmodules: #{e.message}"
        return 1
      end

      # Run validations
      results = run_validations(entries)

      # Generate and display report
      formatter = ReportFormatter.new(results, submodule_count: entries.length)
      puts formatter.format

      # Return exit code based on results
      results.any?(&:failed?) ? 1 : 0
    rescue StandardError => e
      puts "Error running report: #{e.message}"
      puts e.backtrace if ENV['DEBUG']
      2
    end

    private

    def run_validations(entries)
      results = []

      # Path validation
      path_validator = PathValidator.new(@repo_root, entries)
      results.concat(path_validator.validate)

      # Initialization validation
      init_validator = InitValidator.new(@repo_root, entries)
      results.concat(init_validator.validate)

      # Dirty status validation
      dirty_validator = DirtyValidator.new(@repo_root, entries)
      results.concat(dirty_validator.validate)

      # Unpushed commits validation
      unpushed_validator = UnpushedValidator.new(@repo_root, entries)
      results.concat(unpushed_validator.validate)

      results
    end
  end
end

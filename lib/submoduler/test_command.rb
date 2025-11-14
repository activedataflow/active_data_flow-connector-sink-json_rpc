# frozen_string_literal: true

require_relative 'submoduler_ini_parser'
require_relative 'test_runner'
require_relative 'test_formatter'

module Submoduler
  # Runs tests across all submodules
  class TestCommand
    def initialize(repo_root, options = {})
      @repo_root = repo_root
      @options = options
    end

    def execute
      parser = SubmodulerIniParser.new(@repo_root)

      unless parser.exists?
        puts "No .submoduler.ini files found. No submodules configured."
        return 0
      end

      # Parse submodule entries
      entries = parser.parse
      
      # Filter by --submodule option if provided
      if @options[:submodules]
        entries = entries.select { |e| @options[:submodules].include?(e.name) }
      end

      # Run tests
      test_results = run_tests(entries)

      # Format and display results
      formatter = TestFormatter.new(
        test_results,
        verbose: @options[:verbose],
        no_color: @options[:no_color]
      )
      puts formatter.format

      # Determine exit code
      has_failures = test_results.any? { |r| r[:status] == :failed || r[:status] == :error }
      has_failures ? 1 : 0

    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace if ENV['DEBUG']
      2
    end

    private

    def run_tests(entries)
      results = []

      entries.each do |entry|
        path = File.join(@repo_root, entry.path)
        
        puts "\n#{colorize("Testing #{entry.name}...", :blue)}" if @options[:verbose]
        
        runner = TestRunner.new(path, entry.name, @options)
        result = runner.run
        results << result

        # Show immediate result in verbose mode
        if @options[:verbose]
          status_text = case result[:status]
                       when :passed then colorize("✓ PASSED", :green)
                       when :failed then colorize("✗ FAILED", :red)
                       when :skipped then colorize("○ SKIPPED (#{result[:skip_reason]})", :yellow)
                       when :error then colorize("✗ ERROR", :red)
                       end
          puts "#{status_text} (#{result[:duration].round(2)}s)\n"
        end
      end

      results
    end

    def colorize(text, color)
      return text if @options[:no_color]
      
      colors = {
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        blue: "\e[34m",
        reset: "\e[0m"
      }
      
      "#{colors[color]}#{text}#{colors[:reset]}"
    end
  end
end

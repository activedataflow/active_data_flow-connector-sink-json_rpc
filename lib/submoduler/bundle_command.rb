# frozen_string_literal: true

require_relative 'submoduler_ini_parser'

module Submoduler
  # Runs bundle command in submodules
  class BundleCommand
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

      puts "Running bundle in #{entries.length} submodule#{entries.length == 1 ? '' : 's'}..."
      puts ""

      results = []
      entries.each do |entry|
        result = run_bundle_in_submodule(entry)
        results << result
      end

      # Summary
      puts ""
      puts "━" * 80
      successful = results.count { |r| r[:success] }
      failed = results.count { |r| !r[:success] }
      
      if failed == 0
        puts colorize("✓ Bundle completed successfully in all submodules", :green)
      else
        puts colorize("✗ Bundle failed in #{failed} submodule#{failed == 1 ? '' : 's'}", :red)
      end
      puts "━" * 80

      failed > 0 ? 1 : 0

    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace if ENV['DEBUG']
      2
    end

    private

    def run_bundle_in_submodule(entry)
      path = File.join(@repo_root, entry.path)
      child_script = File.join(path, 'bin', 'submoduler_child.rb')

      puts colorize("→ #{entry.name}", :blue)

      # Check if submodule is initialized
      unless File.exist?(File.join(path, '.git'))
        puts colorize("  ○ Skipped (not initialized)", :yellow)
        puts ""
        return { submodule: entry.name, success: true, skipped: true }
      end

      # Check if submoduler_child.rb exists
      unless File.exist?(child_script)
        puts colorize("  ✗ Error: bin/submoduler_child.rb not found", :red)
        puts ""
        return { submodule: entry.name, success: false, error: "Missing submoduler_child.rb" }
      end

      # Run bundle command
      Dir.chdir(path) do
        if @options[:verbose]
          system("ruby bin/submoduler_child.rb bundle")
        else
          output = `ruby bin/submoduler_child.rb bundle 2>&1`
          success = $?.success?
          
          if success
            puts colorize("  ✓ Bundle completed", :green)
          else
            puts colorize("  ✗ Bundle failed", :red)
            puts ""
            puts "  Output:"
            output.lines.each { |line| puts "    #{line}" }
          end
        end
        
        success = $?.success?
        puts ""
        
        { submodule: entry.name, success: success }
      end
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

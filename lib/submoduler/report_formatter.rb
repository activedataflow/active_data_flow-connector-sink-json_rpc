# frozen_string_literal: true

module Submoduler
  # Formats validation results for console output
  class ReportFormatter
    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
      reset: "\e[0m"
    }.freeze

    def initialize(results, submodule_count: 0)
      @results = results
      @submodule_count = submodule_count
    end

    def format
      output = []
      output << format_header
      output << ""
      output << format_configuration_section
      output << ""
      output << format_path_section
      output << ""
      output << format_initialization_section
      output << ""
      output << format_dirty_section
      output << ""
      output << format_unpushed_section
      output << ""
      output << format_summary
      output.join("\n")
    end

    private

    def format_header
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      [
        "Submodule Configuration Report",
        "Generated: #{timestamp}",
        "━" * 60
      ].join("\n")
    end

    def format_configuration_section
      output = ["📋 Submodule Configuration Check"]
      
      if @submodule_count > 0
        output << "  #{colorize('✓', :green)} Found .submoduler.ini files"
        output << "  #{colorize('✓', :green)} Parsed #{@submodule_count} submodule #{@submodule_count == 1 ? 'entry' : 'entries'}"
      else
        output << "  #{colorize('✗', :red)} No submodules configured"
      end
      
      output.join("\n")
    end

    def format_path_section
      path_results = @results.select { |r| r.check_type == :path_exists }
      format_section("📁 Path Validation", path_results)
    end

    def format_initialization_section
      init_results = @results.select { |r| r.check_type == :initialization }
      format_section("🔧 Initialization Check", init_results)
    end

    def format_dirty_section
      dirty_results = @results.select { |r| r.check_type == :dirty }
      format_section("🔍 Clean Status Check", dirty_results)
    end

    def format_unpushed_section
      unpushed_results = @results.select { |r| r.check_type == :unpushed }
      format_section("📤 Push Status Check", unpushed_results)
    end

    def format_section(title, results)
      return "#{title}\n  No checks performed" if results.empty?

      output = [title]
      
      results.each do |result|
        if result.passed?
          output << "  #{colorize('✓', :green)} #{result.submodule_name}"
        else
          output << "  #{colorize('✗', :red)} #{result.submodule_name}"
          output << "    #{result.message}" if result.message
        end
      end
      
      output.join("\n")
    end

    def format_summary
      passed = @results.count(&:passed?)
      failed = @results.count(&:failed?)
      
      [
        "━" * 60,
        "Summary: #{colorize("#{passed} passed", :green)}, #{colorize("#{failed} failed", failed > 0 ? :red : :green)}"
      ].join("\n")
    end

    def colorize(text, color)
      "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end
  end
end

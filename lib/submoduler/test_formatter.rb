# frozen_string_literal: true

module Submoduler
  # Formats test results for console output
  class TestFormatter
    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
      reset: "\e[0m"
    }.freeze

    def initialize(test_results, options = {})
      @test_results = test_results
      @options = options
    end

    def format
      output = []
      output << format_header
      output << ""
      output << format_results_table
      
      # Show failure details if any tests failed
      failed_results = @test_results.select { |r| r[:status] == :failed || r[:status] == :error }
      if failed_results.any? && !@options[:verbose]
        output << ""
        output << format_failure_details(failed_results)
      end

      output << ""
      output << format_summary
      output.join("\n")
    end

    private

    def format_header
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      [
        "Submodule Test Report",
        "Generated: #{timestamp}",
        "━" * 80
      ].join("\n")
    end

    def format_results_table
      output = ["🧪 Test Results", ""]

      # Calculate column widths
      max_submodule = @test_results.map { |r| r[:submodule_name].length }.max || 20
      max_submodule = [max_submodule, 15].max

      # Header
      output << sprintf("  %-#{max_submodule}s  %-10s  %-10s", "Submodule", "Status", "Duration")
      output << "  " + "─" * (max_submodule + 24)

      # Rows
      @test_results.each do |result|
        submodule = result[:submodule_name]
        status_display = format_status(result[:status], result[:skip_reason])
        duration_display = format_duration(result[:duration])

        output << sprintf("  %-#{max_submodule}s  %s  %-10s", 
                         submodule, status_display, duration_display)
      end

      output.join("\n")
    end

    def format_status(status, skip_reason = nil)
      case status
      when :passed
        colorize("✓ PASSED ", :green)
      when :failed
        colorize("✗ FAILED ", :red)
      when :skipped
        reason = skip_reason ? " (#{skip_reason})" : ""
        colorize("○ SKIPPED", :yellow) + reason
      when :error
        colorize("✗ ERROR  ", :red)
      else
        "UNKNOWN"
      end
    end

    def format_duration(duration)
      return "N/A" if duration.nil? || duration == 0
      "#{duration.round(2)}s"
    end

    def format_failure_details(failed_results)
      output = [colorize("❌ Failure Details", :red), ""]

      failed_results.each do |result|
        output << "  #{colorize("#{result[:submodule_name]}:", :red)}"
        
        if result[:error]
          output << "    Error: #{result[:error]}"
        end
        
        if result[:output] && !result[:output].empty?
          output << ""
          # Show last 30 lines of output
          lines = result[:output].lines
          if lines.length > 30
            output << "    ... (showing last 30 lines)"
            lines = lines.last(30)
          end
          lines.each do |line|
            output << "    #{line.rstrip}"
          end
        end
        
        output << ""
      end

      output.join("\n")
    end

    def format_summary
      passed = @test_results.count { |r| r[:status] == :passed }
      failed = @test_results.count { |r| r[:status] == :failed }
      error = @test_results.count { |r| r[:status] == :error }
      skipped = @test_results.count { |r| r[:status] == :skipped }
      total = @test_results.length

      parts = []
      parts << colorize("#{passed} passed", :green) if passed > 0
      parts << colorize("#{failed} failed", :red) if failed > 0
      parts << colorize("#{error} errors", :red) if error > 0
      parts << colorize("#{skipped} skipped", :yellow) if skipped > 0

      summary = parts.join(", ")
      
      [
        "━" * 80,
        "Summary: #{summary} (#{total} total)"
      ].join("\n")
    end

    def colorize(text, color)
      return text if @options[:no_color]
      "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end
  end
end

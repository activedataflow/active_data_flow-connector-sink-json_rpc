# frozen_string_literal: true

module Submoduler
  # Formats version information for console output
  class VersionFormatter
    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
      reset: "\e[0m"
    }.freeze

    def initialize(version_infos, options = {})
      @version_infos = version_infos
      @options = options
      @mismatch_info = options[:mismatch_info]
      @sync_results = options[:sync_results]
    end

    def format
      output = []
      output << format_header
      output << ""
      output << format_version_table
      
      if @mismatch_info && @mismatch_info[:has_mismatch]
        output << ""
        output << format_mismatch_warning
      end

      if @sync_results
        output << ""
        output << format_sync_summary
      end

      output << ""
      output << format_footer
      output.join("\n")
    end

    private

    def format_header
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      [
        "Submodule Version Report",
        "Generated: #{timestamp}",
        "━" * 80
      ].join("\n")
    end

    def format_version_table
      output = ["📦 Gem Versions", ""]

      # Calculate column widths
      max_submodule = @version_infos.map { |v| v[:submodule_name].length }.max || 20
      max_gem = @version_infos.map { |v| (v[:gem_name] || "N/A").length }.max || 20
      max_version = @version_infos.map { |v| (v[:version] || "N/A").length }.max || 10

      # Ensure minimum widths
      max_submodule = [max_submodule, 15].max
      max_gem = [max_gem, 20].max
      max_version = [max_version, 10].max

      # Header
      output << sprintf("  %-#{max_submodule}s  %-#{max_gem}s  %-#{max_version}s", 
                       "Submodule", "Gem Name", "Version")
      output << "  " + "─" * (max_submodule + max_gem + max_version + 4)

      # Rows
      @version_infos.each do |info|
        submodule = info[:submodule_name]
        gem_name = info[:gem_name] || "N/A"
        version = info[:version] || info[:error] || "N/A"

        # Color code based on mismatch
        if info[:error]
          version_display = colorize(version, :yellow)
        elsif @mismatch_info && @mismatch_info[:has_mismatch]
          if info[:version] == @mismatch_info[:highest_version]
            version_display = colorize(version, :green)
          else
            version_display = colorize(version, :red)
          end
        else
          version_display = colorize(version, :green)
        end

        output << sprintf("  %-#{max_submodule}s  %-#{max_gem}s  %s", 
                         submodule, gem_name, version_display)
      end

      output.join("\n")
    end

    def format_mismatch_warning
      output = [colorize("⚠️  Version Mismatch Detected", :yellow), ""]
      output << "  Highest version: #{colorize(@mismatch_info[:highest_version], :green)}"
      output << ""
      output << "  Versions found:"
      
      @mismatch_info[:versions].sort_by { |v, _| v }.reverse.each do |version, submodules|
        marker = version == @mismatch_info[:highest_version] ? "✓" : "✗"
        color = version == @mismatch_info[:highest_version] ? :green : :red
        output << "    #{colorize(marker, color)} #{version}: #{submodules.join(', ')}"
      end

      if @options[:dry_run]
        new_version = GemVersionUpdater.increment_version(@mismatch_info[:highest_version])
        output << ""
        output << "  Would synchronize all to: #{colorize(new_version, :blue)}"
      elsif !@sync_results
        new_version = GemVersionUpdater.increment_version(@mismatch_info[:highest_version])
        output << ""
        output << "  Run with --sync to update all to: #{colorize(new_version, :blue)}"
      end

      output.join("\n")
    end

    def format_sync_summary
      output = [colorize("✓ Version Synchronization Complete", :green), ""]
      
      updated_count = @sync_results.count { |r| r[:success] }
      failed_count = @sync_results.count { |r| !r[:success] }

      output << "  Updated #{updated_count} submodule#{updated_count == 1 ? '' : 's'}"
      
      if failed_count > 0
        output << "  #{colorize("Failed to update #{failed_count} submodule#{failed_count == 1 ? '' : 's'}", :red)}"
      end

      output << ""
      output << "  Changes:"
      @sync_results.each do |result|
        if result[:success]
          output << "    #{colorize('✓', :green)} #{result[:submodule_name]}: #{result[:old_version]} → #{result[:new_version]}"
        else
          output << "    #{colorize('✗', :red)} #{result[:submodule_name]}: #{result[:error]}"
        end
      end

      output.join("\n")
    end

    def format_footer
      total = @version_infos.length
      with_version = @version_infos.count { |v| v[:version] }
      without_version = total - with_version

      parts = ["Total: #{total} submodule#{total == 1 ? '' : 's'}"]
      parts << "#{with_version} with versions" if with_version > 0
      parts << "#{without_version} without versions" if without_version > 0

      "━" * 80 + "\n" + parts.join(", ")
    end

    def colorize(text, color)
      return text if @options[:no_color]
      "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end
  end
end

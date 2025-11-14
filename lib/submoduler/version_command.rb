# frozen_string_literal: true

require_relative 'submoduler_ini_parser'
require_relative 'gem_version_detector'
require_relative 'gem_version_updater'
require_relative 'version_formatter'

module Submoduler
  # Manages gem versions across submodules
  class VersionCommand
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

      # Detect versions
      version_infos = detect_versions(entries)

      # Check for version mismatches
      mismatch_info = check_version_mismatch(version_infos)

      # Synchronize versions if requested
      sync_results = nil
      if @options[:sync] && mismatch_info[:has_mismatch]
        if @options[:dry_run]
          # Just show what would happen
          sync_results = []
        else
          new_version = GemVersionUpdater.increment_version(mismatch_info[:highest_version])
          sync_results = synchronize_versions(version_infos, new_version)
        end
      end

      # Format and display results
      formatter = VersionFormatter.new(
        version_infos,
        mismatch_info: mismatch_info,
        sync_results: sync_results,
        dry_run: @options[:dry_run],
        no_color: @options[:no_color]
      )
      puts formatter.format

      # Determine exit code
      return 0 if @options[:dry_run]
      return 0 if sync_results && sync_results.all? { |r| r[:success] }
      return 1 if mismatch_info[:has_mismatch] && !@options[:sync]
      return 0

    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace if ENV['DEBUG']
      2
    end

    private

    def detect_versions(entries)
      entries.map do |entry|
        path = File.join(@repo_root, entry.path)
        detector = GemVersionDetector.new(path, entry.name)
        detector.detect
      end
    end

    def check_version_mismatch(version_infos)
      # Get all valid versions
      versions = version_infos
        .select { |v| v[:version] }
        .map { |v| v[:version] }
        .uniq

      return { has_mismatch: false } if versions.length <= 1

      # Find highest version
      highest = versions.max_by { |v| version_sort_key(v) }

      # Group submodules by version
      version_groups = {}
      version_infos.each do |info|
        next unless info[:version]
        version_groups[info[:version]] ||= []
        version_groups[info[:version]] << info[:submodule_name]
      end

      {
        has_mismatch: true,
        highest_version: highest,
        versions: version_groups
      }
    end

    def version_sort_key(version_string)
      parsed = GemVersionUpdater.parse_version(version_string)
      return [0, 0, 0] unless parsed
      [parsed[:major], parsed[:minor], parsed[:patch]]
    end

    def synchronize_versions(version_infos, new_version)
      results = []

      version_infos.each do |info|
        # Skip if no version file or already at target version
        next unless info[:version_file_path]
        next if info[:version] == new_version

        updater = GemVersionUpdater.new(info, new_version)
        result = updater.update
        
        results << {
          submodule_name: info[:submodule_name],
          success: result[:success],
          old_version: result[:old_version],
          new_version: result[:new_version],
          error: result[:error]
        }
      end

      results
    end
  end
end

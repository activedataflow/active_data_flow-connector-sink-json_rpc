# frozen_string_literal: true

module Submoduler
  # Updates gem version in version files and gemspec
  class GemVersionUpdater
    attr_reader :version_info, :new_version

    def initialize(version_info, new_version)
      @version_info = version_info
      @new_version = new_version
    end

    def update
      updated_files = []

      # Update version file if it exists
      if @version_info[:version_file_path] && File.exist?(@version_info[:version_file_path])
        update_version_file(@version_info[:version_file_path])
        updated_files << @version_info[:version_file_path]
      end

      {
        success: true,
        updated_files: updated_files,
        old_version: @version_info[:version],
        new_version: @new_version
      }
    rescue StandardError => e
      {
        success: false,
        error: e.message,
        updated_files: []
      }
    end

    def self.parse_version(version_string)
      return nil unless version_string

      parts = version_string.split('.')
      return nil unless parts.length >= 2

      {
        major: parts[0].to_i,
        minor: parts[1].to_i,
        patch: parts[2]&.to_i || 0
      }
    end

    def self.increment_version(version_string)
      parsed = parse_version(version_string)
      return nil unless parsed

      # Increment patch version
      new_patch = parsed[:patch] + 1
      "#{parsed[:major]}.#{parsed[:minor]}.#{new_patch}"
    end

    def self.compare_versions(v1, v2)
      p1 = parse_version(v1)
      p2 = parse_version(v2)
      
      return 0 unless p1 && p2

      # Compare major
      return 1 if p1[:major] > p2[:major]
      return -1 if p1[:major] < p2[:major]

      # Compare minor
      return 1 if p1[:minor] > p2[:minor]
      return -1 if p1[:minor] < p2[:minor]

      # Compare patch
      return 1 if p1[:patch] > p2[:patch]
      return -1 if p1[:patch] < p2[:patch]

      0
    end

    private

    def update_version_file(file_path)
      content = File.read(file_path)
      old_version = @version_info[:version]

      # Replace VERSION = "old" with VERSION = "new"
      updated_content = content.gsub(
        /(VERSION\s*=\s*["'])#{Regexp.escape(old_version)}(["'])/,
        "\\1#{@new_version}\\2"
      )

      File.write(file_path, updated_content)
    end
  end
end

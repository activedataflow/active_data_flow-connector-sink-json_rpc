# frozen_string_literal: true

module Submoduler
  # Detects gem version information from gemspec and version files
  class GemVersionDetector
    attr_reader :submodule_path, :submodule_name

    def initialize(submodule_path, submodule_name)
      @submodule_path = submodule_path
      @submodule_name = submodule_name
    end

    def detect
      # Check for .submoduler.ini file first
      ini_path = File.join(@submodule_path, '.submoduler.ini')
      unless File.exist?(ini_path)
        return {
          submodule_name: @submodule_name,
          gem_name: nil,
          version: nil,
          gemspec_path: nil,
          version_file_path: nil,
          error: "Missing .submoduler.ini file"
        }
      end

      gemspec_path = find_gemspec
      
      unless gemspec_path
        return {
          submodule_name: @submodule_name,
          gem_name: nil,
          version: nil,
          gemspec_path: nil,
          version_file_path: nil,
          error: "No gemspec found"
        }
      end

      gem_name = extract_gem_name(gemspec_path)
      version_file_path = find_version_file
      
      # Require discrete version.rb file
      unless version_file_path
        return {
          submodule_name: @submodule_name,
          gem_name: gem_name,
          version: nil,
          gemspec_path: gemspec_path,
          version_file_path: nil,
          error: "No discrete version.rb file found"
        }
      end

      version = extract_version_from_file(version_file_path)

      {
        submodule_name: @submodule_name,
        gem_name: gem_name,
        version: version,
        gemspec_path: gemspec_path,
        version_file_path: version_file_path,
        error: version ? nil : "Could not extract version from version.rb"
      }
    rescue StandardError => e
      {
        submodule_name: @submodule_name,
        gem_name: nil,
        version: nil,
        gemspec_path: nil,
        version_file_path: nil,
        error: "Error: #{e.message}"
      }
    end

    private

    def find_gemspec
      return nil unless File.directory?(@submodule_path)
      
      Dir.glob(File.join(@submodule_path, '*.gemspec')).first
    end

    def extract_gem_name(gemspec_path)
      content = File.read(gemspec_path)
      
      # Match: spec.name = "gem-name"
      if content =~ /spec\.name\s*=\s*["']([^"']+)["']/
        return Regexp.last_match(1)
      end
      
      # Fallback to filename
      File.basename(gemspec_path, '.gemspec')
    end

    def find_version_file
      return nil unless File.directory?(@submodule_path)
      
      # Only look for discrete version.rb files
      patterns = [
        'lib/**/version.rb',
        'lib/*/version.rb',
        'version.rb'
      ]
      
      patterns.each do |pattern|
        files = Dir.glob(File.join(@submodule_path, pattern))
        return files.first if files.any?
      end
      
      nil
    end

    def extract_version_from_file(version_file_path)
      content = File.read(version_file_path)
      
      # Match: VERSION = "0.1.0" or VERSION = '0.1.0'
      if content =~ /VERSION\s*=\s*["']([^"']+)["']/
        return Regexp.last_match(1)
      end
      
      nil
    end
  end
end

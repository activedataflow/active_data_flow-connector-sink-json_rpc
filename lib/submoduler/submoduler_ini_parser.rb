# frozen_string_literal: true

require 'pathname'
require_relative 'ini_file_parser'
require_relative 'submodule_entry'
require_relative 'git_executor'

module Submoduler
  # Discovers and parses .submoduler.ini files as source of truth
  class SubmodulerIniParser
    attr_reader :repo_root, :parent_ini_path

    def initialize(repo_root)
      @repo_root = repo_root
      @parent_ini_path = File.join(repo_root, '.submoduler.ini')
    end

    def exists?
      find_ini_files.any? || File.exist?(@parent_ini_path)
    end

    def parse
      entries = []

      # Find all child .submoduler.ini files
      ini_files = find_ini_files

      ini_files.each do |file_path|
        begin
          entry = parse_submodule_ini(file_path)
          entries << entry if entry
        rescue StandardError => e
          warn "Warning: Error parsing #{file_path}: #{e.message}"
        end
      end

      entries
    end

    def parse_parent_ini
      return [] unless File.exist?(@parent_ini_path)

      begin
        ini_data = IniFileParser.parse(@parent_ini_path)
        submodules = []

        ini_data.each do |section_name, section_data|
          # Match [submodule "name"] sections
          if section_name =~ /^submodule "([^"]+)"$/
            name = Regexp.last_match(1)
            
            submodules << {
              name: name,
              path: section_data['path'],
              url: section_data['url']
            }
          end
        end

        submodules
      rescue StandardError => e
        warn "Warning: Error parsing parent .submoduler.ini: #{e.message}"
        []
      end
    end

    private

    def find_ini_files
      ini_files = []

      # Search in common submodule directories
      search_paths = [
        'submodules/**/.submoduler.ini',
        'examples/**/.submoduler.ini'
      ]

      search_paths.each do |pattern|
        Dir.glob(File.join(@repo_root, pattern)).each do |file|
          # Exclude the parent .submoduler.ini
          ini_files << file unless file == @parent_ini_path
        end
      end

      ini_files
    end

    def parse_submodule_ini(file_path)
      ini_data = IniFileParser.parse(file_path)

      # Validate required sections
      unless ini_data['parent'] && ini_data['parent']['url']
        raise "Missing [parent] url in #{file_path}"
      end

      # Extract submodule info from file location
      extract_submodule_info(file_path, ini_data)
    end

    def extract_submodule_info(file_path, ini_data)
      # Get relative path from repo root
      relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(@repo_root))

      # Remove .submoduler.ini from path to get submodule directory
      submodule_path = File.dirname(relative_path).to_s

      # Extract name from path (e.g., "submodules/core/core" -> "core/core")
      name = submodule_path.sub(/^(submodules|examples)\//, '')

      # Get URL from git remote in submodule directory
      url = get_git_remote_url(File.join(@repo_root, submodule_path))

      # Store parent URL for validation
      parent_url = ini_data['parent']['url']

      SubmoduleEntry.new(
        name: name,
        path: submodule_path,
        url: url || "unknown",
        parent_url: parent_url
      )
    end

    def get_git_remote_url(submodule_dir)
      return nil unless File.directory?(File.join(submodule_dir, '.git'))

      executor = GitExecutor.new(submodule_dir)
      result = executor.execute('git config --get remote.origin.url')
      
      result[:success] ? result[:output] : nil
    end
  end
end

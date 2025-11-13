# frozen_string_literal: true

module Submoduler
  # Base class for all submoduler commands
  class BaseCommand
    attr_reader :repo_root, :options

    def initialize(repo_root, options = {})
      @repo_root = repo_root
      @options = options
    end

    def execute
      raise NotImplementedError, "Subclasses must implement #execute"
    end

    protected

    def parser
      @parser ||= GitModulesParser.new(@repo_root)
    end

    def submodule_entries
      @submodule_entries ||= begin
        return [] unless parser.exists?
        parser.parse
      end
    end

    def filtered_submodules
      return submodule_entries unless @options[:submodules]
      
      filter = Array(@options[:submodules])
      submodule_entries.select { |entry| filter.include?(entry.name) }
    end

    def dry_run?
      @options[:dry_run] == true
    end

    def verbose?
      @options[:verbose] == true
    end
  end
end

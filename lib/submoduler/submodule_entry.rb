# frozen_string_literal: true

module Submoduler
  # Represents a parsed submodule entry from .gitmodules or .submoduler.ini
  class SubmoduleEntry
    attr_reader :name, :path, :url, :parent_url

    def initialize(name:, path:, url:, parent_url: nil)
      @name = name
      @path = path
      @url = url
      @parent_url = parent_url
    end

    def to_s
      "#{name} (#{path})"
    end
  end
end

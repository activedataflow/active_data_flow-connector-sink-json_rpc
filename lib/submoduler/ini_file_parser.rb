# frozen_string_literal: true

module Submoduler
  # Parses INI file format
  class IniFileParser
    class ParseError < StandardError; end

    def self.parse(file_path)
      content = File.read(file_path)
      parse_content(content)
    rescue Errno::ENOENT
      raise ParseError, "File not found: #{file_path}"
    rescue Errno::EACCES
      raise ParseError, "Permission denied: #{file_path}"
    end

    def self.parse_content(content)
      sections = {}
      current_section = nil

      content.each_line.with_index do |line, line_num|
        line = line.strip

        # Skip empty lines and comments
        next if line.empty? || line.start_with?('#', ';')

        # Section header: [section_name] or [submodule "name"]
        if line =~ /^\[([^\]]+)\]$/
          current_section = Regexp.last_match(1)
          sections[current_section] = {}
        # Key-value pair: key = value (with optional tab indentation)
        elsif line =~ /^\s*(\w+)\s*=\s*(.+)$/
          key = Regexp.last_match(1)
          value = Regexp.last_match(2).strip
          
          if current_section
            sections[current_section][key] = value
          else
            raise ParseError, "Key-value pair outside of section at line #{line_num + 1}"
          end
        elsif !line.empty?
          # Non-empty line that doesn't match expected format
          raise ParseError, "Invalid INI format at line #{line_num + 1}: #{line}"
        end
      end

      sections
    end
  end
end

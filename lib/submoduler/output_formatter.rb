# frozen_string_literal: true

module Submoduler
  # Formats output with colors and symbols
  class OutputFormatter
    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
      reset: "\e[0m"
    }.freeze

    SYMBOLS = {
      success: '✓',
      failure: '✗',
      warning: '⚠',
      info: 'ℹ'
    }.freeze

    def initialize(no_color: false)
      @no_color = no_color
    end

    def colorize(text, color)
      return text if @no_color || !COLORS.key?(color)
      "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end

    def success(text)
      "#{colorize(SYMBOLS[:success], :green)} #{text}"
    end

    def failure(text)
      "#{colorize(SYMBOLS[:failure], :red)} #{text}"
    end

    def warning(text)
      "#{colorize(SYMBOLS[:warning], :yellow)} #{text}"
    end

    def info(text)
      "#{colorize(SYMBOLS[:info], :blue)} #{text}"
    end

    def header(text)
      separator = '━' * 60
      "\n#{text}\n#{separator}\n"
    end

    def section(title)
      "\n#{colorize("#{title}", :blue)}\n"
    end
  end
end

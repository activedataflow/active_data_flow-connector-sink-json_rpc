#!/usr/bin/env ruby
# frozen_string_literal: true

require 'erb'
require 'pathname'

# Submoduler Child - Submodule-level commands
class SubmodulerChild
  def initialize(args)
    @args = args
    @root_dir = File.expand_path('..', __dir__)
  end

  def run
    command = @args.first

    case command
    when 'bundle'
      bundle_command
    when 'generate-gemfile'
      generate_gemfile
    when '--help', '-h', nil
      show_usage
      0
    else
      puts "Error: Unknown command '#{command}'"
      show_usage
      1
    end
  end

  private

  def bundle_command
    # Generate Gemfile first
    generate_gemfile

    # Run bundle install
    puts "\nRunning bundle install..."
    Dir.chdir(@root_dir) do
      system('bundle install')
      $?.success? ? 0 : 1
    end
  end

  def generate_gemfile
    # Check for Gemfile template files
    preamble_path = File.join(@root_dir, 'bin', 'Gemfile_preamble.rb')
    template_path = File.join(@root_dir, 'bin', 'Gemfile.erb')

    unless File.exist?(template_path)
      puts "Error: Gemfile.erb template not found at #{template_path}"
      return 1
    end

    # Read the preamble (if exists) and template files
    preamble = File.exist?(preamble_path) ? File.read(preamble_path) : ''
    template = File.read(template_path)

    # Combine preamble and template
    combined_content = preamble + "\n" + template

    # Process the ERB template
    erb = ERB.new(combined_content)
    result = erb.result

    # Write the generated Gemfile to the root directory
    File.write(File.join(@root_dir, 'Gemfile'), result)

    puts "✓ Generated Gemfile from Gemfile.erb template"
    0
  end

  def show_usage
    puts <<~USAGE
      Submoduler Child - Submodule-level commands

      Usage:
        submoduler_child.rb <command>

      Commands:
        bundle              Generate Gemfile and run bundle install
        generate-gemfile    Generate Gemfile from Gemfile.erb template
        --help, -h          Show this help message

      Examples:
        submoduler_child.rb bundle
        submoduler_child.rb generate-gemfile
    USAGE
  end
end

# Run if executed directly
if __FILE__ == $0
  exit SubmodulerChild.new(ARGV).run
end

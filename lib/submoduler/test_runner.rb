# frozen_string_literal: true

module Submoduler
  # Runs tests for a single submodule
  class TestRunner
    attr_reader :submodule_path, :submodule_name, :options

    def initialize(submodule_path, submodule_name, options = {})
      @submodule_path = submodule_path
      @submodule_name = submodule_name
      @options = options
    end

    def run
      start_time = Time.now

      # Check if submodule is initialized
      unless File.exist?(File.join(@submodule_path, '.git'))
        return {
          submodule_name: @submodule_name,
          status: :skipped,
          output: nil,
          skip_reason: "Not initialized",
          duration: 0,
          error: nil
        }
      end

      # Check if tests exist
      unless has_tests?
        return {
          submodule_name: @submodule_name,
          status: :skipped,
          output: nil,
          skip_reason: "No tests found",
          duration: 0,
          error: nil
        }
      end

      # Run bundle install if Gemfile exists
      if File.exist?(File.join(@submodule_path, 'Gemfile'))
        bundle_result = bundle_install
        unless bundle_result[:success]
          return {
            submodule_name: @submodule_name,
            status: :error,
            output: bundle_result[:output],
            skip_reason: nil,
            duration: Time.now - start_time,
            error: "Bundle install failed"
          }
        end
      end

      # Execute tests
      test_result = execute_tests
      duration = Time.now - start_time

      {
        submodule_name: @submodule_name,
        status: test_result[:success] ? :passed : :failed,
        output: test_result[:output],
        skip_reason: nil,
        duration: duration,
        error: test_result[:error]
      }
    rescue StandardError => e
      {
        submodule_name: @submodule_name,
        status: :error,
        output: nil,
        skip_reason: nil,
        duration: Time.now - start_time,
        error: "Error: #{e.message}"
      }
    end

    private

    def has_tests?
      File.directory?(File.join(@submodule_path, 'spec')) ||
        File.directory?(File.join(@submodule_path, 'test'))
    end

    def bundle_install
      puts "  Installing dependencies for #{@submodule_name}..." if @options[:verbose]
      
      Dir.chdir(@submodule_path) do
        output = `bundle install 2>&1`
        success = $?.success?
        
        puts output if @options[:verbose]
        
        { success: success, output: output }
      end
    end

    def detect_test_command
      has_gemfile = File.exist?(File.join(@submodule_path, 'Gemfile'))
      
      if has_gemfile
        # Prefer bundle exec rspec
        return 'bundle exec rspec' if has_rspec?
        return 'bundle exec rake spec' if has_rake_spec?
      else
        # Try rspec directly
        return 'rspec' if command_exists?('rspec')
      end
      
      # Fallback
      'bundle exec rspec'
    end

    def has_rspec?
      gemfile_lock = File.join(@submodule_path, 'Gemfile.lock')
      return false unless File.exist?(gemfile_lock)
      
      content = File.read(gemfile_lock)
      content.include?('rspec')
    end

    def has_rake_spec?
      rakefile = File.join(@submodule_path, 'Rakefile')
      return false unless File.exist?(rakefile)
      
      content = File.read(rakefile)
      content.include?('spec')
    end

    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end

    def execute_tests
      command = detect_test_command
      
      puts "  Running: #{command}" if @options[:verbose]
      
      Dir.chdir(@submodule_path) do
        if @options[:verbose]
          # Stream output in real-time
          system(command)
          success = $?.success?
          { success: success, output: nil, error: success ? nil : "Tests failed" }
        else
          # Capture output
          output = `#{command} 2>&1`
          success = $?.success?
          { success: success, output: output, error: success ? nil : "Tests failed" }
        end
      end
    end
  end
end

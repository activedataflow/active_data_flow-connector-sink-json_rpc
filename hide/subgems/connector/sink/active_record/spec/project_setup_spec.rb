# frozen_string_literal: true

require 'bundler'

RSpec.describe 'Project Setup' do
  describe 'Gemfile' do
    it 'exists' do
      expect(File.exist?('Gemfile')).to be true
    end

    it 'contains rubygems.org source' do
      content = File.read('Gemfile')
      expect(content).to include("source 'https://rubygems.org'")
    end

    it 'contains git_source configuration' do
      content = File.read('Gemfile')
      expect(content).to include('git_source(:github)')
    end

    it 'contains active_data_flow-core-core dependency' do
      content = File.read('Gemfile')
      expect(content).to include("gem 'active_data_flow-core-core'")
      expect(content).to include("path: 'core_core'")
    end

    it 'contains rspec in development group' do
      content = File.read('Gemfile')
      expect(content).to include('group :development, :test')
      expect(content).to include("gem 'rspec'")
    end

    it 'uses frozen_string_literal pragma' do
      first_line = File.open('Gemfile', &:readline).strip
      expect(first_line).to eq('# frozen_string_literal: true')
    end
  end

  describe '.kiro directory structure' do
    it 'has .kiro directory' do
      expect(Dir.exist?('.kiro')).to be true
    end

    it 'has .kiro/specs directory' do
      expect(Dir.exist?('.kiro/specs')).to be true
    end

    it 'has project-setup spec directory' do
      expect(Dir.exist?('.kiro/specs/project-setup')).to be true
    end

    it 'has source spec directory' do
      expect(Dir.exist?('.kiro/specs/source')).to be true
    end

    it 'has sink spec directory' do
      expect(Dir.exist?('.kiro/specs/sink')).to be true
    end
  end

  describe 'init file' do
    let(:init_file) { 'lib/active_data_flow-active_record.rb' }

    it 'exists' do
      expect(File.exist?(init_file)).to be true
    end

    it 'uses frozen_string_literal pragma' do
      first_line = File.open(init_file, &:readline).strip
      expect(first_line).to eq('# frozen_string_literal: true')
    end

    it 'requires dependencies in correct order' do
      content = File.read(init_file)
      lines = content.lines.map(&:strip).reject(&:empty?).reject { |l| l.start_with?('#') }
      
      active_record_idx = lines.index { |l| l.include?("require 'active_record'") }
      active_support_idx = lines.index { |l| l.include?("require 'active_support'") }
      active_data_flow_idx = lines.index { |l| l.include?("require 'active_data_flow'") }
      version_idx = lines.index { |l| l.include?('active_record/version') }
      
      expect(active_record_idx).to be < active_data_flow_idx
      expect(active_support_idx).to be < active_data_flow_idx
      expect(active_data_flow_idx).to be < version_idx
    end

    it 'requires source connector' do
      content = File.read(init_file)
      expect(content).to include("require_relative 'active_data_flow/source/active_record'")
    end

    it 'requires sink connector' do
      content = File.read(init_file)
      expect(content).to include("require_relative 'active_data_flow/sink/active_record'")
    end
  end

  describe 'gemspec' do
    let(:gemspec_file) { 'active_dataflow-connector-active_record.gemspec' }
    let(:spec) { Gem::Specification.load(gemspec_file) }

    it 'exists' do
      expect(File.exist?(gemspec_file)).to be true
    end

    it 'has correct name' do
      expect(spec.name).to eq('active_dataflow-connector-active_record')
    end

    it 'requires version file' do
      content = File.read(gemspec_file)
      expect(content).to include('require_relative "lib/active_data_flow/active_record/version"')
    end

    it 'includes lib files' do
      content = File.read(gemspec_file)
      expect(content).to include('Dir.glob("{lib}/**/*")')
    end

    it 'includes documentation files' do
      content = File.read(gemspec_file)
      expect(content).to include('README.md')
      expect(content).to include('LICENSE.txt')
      expect(content).to include('CHANGELOG.md')
    end

    it 'has active_data_flow-core-core runtime dependency' do
      dep = spec.dependencies.find { |d| d.name == 'active_data_flow-core-core' }
      expect(dep).not_to be_nil
      expect(dep.type).to eq(:runtime)
    end

    it 'has activerecord runtime dependency' do
      dep = spec.dependencies.find { |d| d.name == 'activerecord' }
      expect(dep).not_to be_nil
      expect(dep.type).to eq(:runtime)
    end

    it 'has activesupport runtime dependency' do
      dep = spec.dependencies.find { |d| d.name == 'activesupport' }
      expect(dep).not_to be_nil
      expect(dep.type).to eq(:runtime)
    end

    it 'has rspec development dependency' do
      dep = spec.dependencies.find { |d| d.name == 'rspec' }
      expect(dep).not_to be_nil
      expect(dep.type).to eq(:development)
    end

    it 'has sqlite3 development dependency' do
      dep = spec.dependencies.find { |d| d.name == 'sqlite3' }
      expect(dep).not_to be_nil
      expect(dep.type).to eq(:development)
    end

    it 'has rubocop development dependency' do
      dep = spec.dependencies.find { |d| d.name == 'rubocop' }
      expect(dep).not_to be_nil
      expect(dep.type).to eq(:development)
    end

    it 'can be built successfully' do
      output = `gem build #{gemspec_file} 2>&1`
      expect($?.success?).to be true
      expect(output).to include('Successfully built RubyGem')
      
      # Clean up
      gem_file = "active_dataflow-connector-active_record-#{spec.version}.gem"
      File.delete(gem_file) if File.exist?(gem_file)
    end
  end

  describe 'documentation files' do
    describe 'LICENSE.txt' do
      it 'exists' do
        expect(File.exist?('LICENSE.txt')).to be true
      end

      it 'contains MIT license' do
        content = File.read('LICENSE.txt')
        expect(content).to include('MIT License')
      end

      it 'has correct copyright' do
        content = File.read('LICENSE.txt')
        expect(content).to include('Copyright (c) 2024 ActiveDataFlow Team')
      end
    end

    describe 'CHANGELOG.md' do
      it 'exists' do
        expect(File.exist?('CHANGELOG.md')).to be true
      end

      it 'follows Keep a Changelog format' do
        content = File.read('CHANGELOG.md')
        expect(content).to include('# Changelog')
        expect(content).to include('Keep a Changelog')
        expect(content).to include('Semantic Versioning')
      end

      it 'has version entry' do
        content = File.read('CHANGELOG.md')
        expect(content).to match(/\[0\.1\.\d+\]/)
      end
    end

    describe 'README.md' do
      it 'exists' do
        expect(File.exist?('README.md')).to be true
      end
    end
  end
end

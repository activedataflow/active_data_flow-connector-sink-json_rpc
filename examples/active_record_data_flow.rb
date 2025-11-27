#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating ActiveRecord connector usage with scopes

require "bundler/setup"
require "active_data_flow"

# This example shows how to use the ActiveRecord connectors
# In a real Rails app, you would have actual models

puts "=== ActiveRecord Source Connector ==="
puts
puts "The source can be created in two ways:"
puts
puts "1. Using named scopes (serializable - recommended):"
puts <<~RUBY
  source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
    model_class: User,
    scope_name: :active  # Calls User.active
  )
  
  # With parameters
  source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
    model_class: User,
    scope_name: :created_after,
    scope_params: [1.week.ago]
  )
RUBY

puts
puts "2. Using a scope directly (for immediate use):"
puts <<~RUBY
  source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
    scope: User.where(active: true).order(:created_at)
  )
  
  # Iterate over records
  source.each do |user|
    puts user.email
  end
RUBY

puts
puts "=== ActiveRecord Sink Connector ==="
puts
puts "The sink writes records to a model:"
puts
puts "Usage:"
puts <<~RUBY
  sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
    model_class: UserBackup
  )
  
  # Write single record
  sink.write(name: "John", email: "john@example.com")
  
  # Write batch of records (uses insert_all for efficiency)
  sink.write_batch([
    { name: "Jane", email: "jane@example.com" },
    { name: "Bob", email: "bob@example.com" }
  ])
RUBY

puts
puts "=== Complete Data Flow Example ==="
puts
puts "Using named scopes (serializable):"
puts <<~RUBY
  # Define a scope in your model
  class User < ApplicationRecord
    scope :recently_active, -> { where("last_login_at > ?", 30.days.ago) }
  end
  
  # Create source using the named scope
  source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
    model_class: User,
    scope_name: :recently_active
  )
  
  # Define sink
  sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
    model_class: UserBackup
  )
  
  # Create data flow with runtime configuration
  # batch_size is configured on the runtime only
  ActiveDataFlow::DataFlow.create!(
    name: "active_users_backup",
    source: source,
    sink: sink,
    runtime_config: {
      batch_size: 100  # Runtime controls how many records to process at once
    }
  )
RUBY

puts
puts "Using direct scope (for immediate execution):"
puts <<~RUBY
  source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
    scope: User.where(active: true)
               .where("last_login_at > ?", 30.days.ago)
               .includes(:profile)
               .order(:created_at)
  )
  
  # Use immediately (runtime will control batch_size)
  source.each do |user|
    # Process user
  end
RUBY

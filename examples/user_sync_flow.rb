# frozen_string_literal: true

# Example: User Sync Data Flow
#
# This example demonstrates a complete data flow that:
# 1. Reads users from a source database
# 2. Transforms the data (filters and maps attributes)
# 3. Writes to a backup/sync destination
#
# Usage:
#   # In a Rails application, place this in app/data_flows/user_sync_flow.rb
#   # The flow will be auto-registered on application startup
#
#   # Or execute manually:
#   flow = UserSyncFlow.new
#   result = flow.execute
#
require 'active_data_flow'
require 'functional_task_supervisor'

class UserSyncFlow
  # ==========================================================================
  # Stage 1: Source - Fetch users from the database
  # ==========================================================================
  class FetchUsersStage < FunctionalTaskSupervisor::Stage
    # Store the source connector at the class level
    # This allows the connector to be configured once and shared across instances
    self.instance = nil # Will be set during flow initialization

    def perform_work
      records = connector.each(batch_size: 100).to_a
      Success(data: records, count: records.size)
    rescue StandardError => e
      Failure(error: "Failed to fetch users: #{e.message}", stage: name)
    end
  end

  # ==========================================================================
  # Stage 2: Transform - Filter and map user attributes
  # ==========================================================================
  class TransformUsersStage < FunctionalTaskSupervisor::Stage
    attr_accessor :input_records

    # Define which attributes to sync
    SYNC_ATTRIBUTES = %w[id email name created_at updated_at].freeze

    def perform_work
      return Failure(error: 'No input records provided', stage: name) if input_records.nil?

      transformed = input_records.map do |record|
        transform_record(record)
      end.compact

      Success(data: transformed, count: transformed.size)
    end

    private

    def transform_record(record)
      # Skip inactive or deleted users
      return nil if record.respond_to?(:deleted?) && record.deleted?
      return nil if record.respond_to?(:active?) && !record.active?

      # Extract only the attributes we want to sync
      attributes = if record.respond_to?(:attributes)
        record.attributes.slice(*SYNC_ATTRIBUTES)
      else
        record.to_h.slice(*SYNC_ATTRIBUTES.map(&:to_sym))
      end

      # Add sync metadata
      attributes.merge(
        'synced_at' => Time.current,
        'source_system' => 'primary'
      )
    end
  end

  # ==========================================================================
  # Stage 3: Sink - Write transformed users to destination
  # ==========================================================================
  class WriteUsersStage < FunctionalTaskSupervisor::Stage
    # Store the sink connector at the class level
    self.instance = nil # Will be set during flow initialization

    attr_accessor :input_records

    def perform_work
      return Failure(error: 'No input records provided', stage: name) if input_records.nil?
      return Success(data: { records_written: 0 }) if input_records.empty?

      result = connector.write_batch(input_records)

      if result.success?
        Success(data: { records_written: input_records.size })
      else
        Failure(error: "Failed to write records: #{result.failure}", stage: name)
      end
    rescue StandardError => e
      Failure(error: "Write failed: #{e.message}", stage: name)
    end
  end

  # ==========================================================================
  # Flow Orchestration
  # ==========================================================================

  attr_reader :source_connector, :sink_connector, :options

  def initialize(source_connector:, sink_connector:, **options)
    @source_connector = source_connector
    @sink_connector = sink_connector
    @options = options

    # Configure stage connectors
    FetchUsersStage.instance = source_connector
    WriteUsersStage.instance = sink_connector
  end

  # Execute the complete data flow
  #
  # @return [Dry::Monads::Result] Success with stats or Failure with error
  def execute
    start_time = Time.current

    # Create stage instances
    fetch_stage = FetchUsersStage.new('fetch_users')
    transform_stage = TransformUsersStage.new('transform_users')
    write_stage = WriteUsersStage.new('write_users')

    # Execute Stage 1: Fetch
    fetch_stage.execute
    return build_failure_result(fetch_stage, start_time) if fetch_stage.failure?

    # Execute Stage 2: Transform
    transform_stage.input_records = fetch_stage.value[:data]
    transform_stage.execute
    return build_failure_result(transform_stage, start_time) if transform_stage.failure?

    # Execute Stage 3: Write
    write_stage.input_records = transform_stage.value[:data]
    write_stage.execute
    return build_failure_result(write_stage, start_time) if write_stage.failure?

    # Build success result
    build_success_result(fetch_stage, transform_stage, write_stage, start_time)
  end

  private

  def build_success_result(fetch_stage, transform_stage, write_stage, start_time)
    Dry::Monads::Success(
      status: :completed,
      duration_seconds: Time.current - start_time,
      stats: {
        fetched: fetch_stage.value[:count],
        transformed: transform_stage.value[:count],
        written: write_stage.value[:data][:records_written]
      }
    )
  end

  def build_failure_result(failed_stage, start_time)
    Dry::Monads::Failure(
      status: :failed,
      failed_stage: failed_stage.name,
      error: failed_stage.error,
      duration_seconds: Time.current - start_time
    )
  end

  # ==========================================================================
  # ActiveDataFlow Registration (for Rails integration)
  # ==========================================================================

  # Register this flow with ActiveDataFlow
  #
  # @param source_scope [ActiveRecord::Relation] Named scope for source data
  # @param sink_model [Class] ActiveRecord model class for destination
  # @param interval [Integer] Run interval in seconds (default: 1 hour)
  # @return [ActiveDataFlow::ActiveRecord::DataFlow] The registered flow
  def self.register(source_scope:, sink_model:, interval: 3600)
    source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
      scope: source_scope
    )

    sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
      model_class: sink_model,
      batch_size: 100
    )

    ActiveDataFlow::ActiveRecord::DataFlow.find_or_create(
      name: 'user_sync_flow',
      source: source,
      sink: sink,
      runtime: { interval: interval, enabled: true }
    )
  end
end

# ==========================================================================
# Example Usage
# ==========================================================================
#
# # In a Rails initializer or data_flows file:
#
# # Option 1: Manual execution with custom connectors
# source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
#   scope: User.active
# )
# sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
#   model_class: UserBackup,
#   batch_size: 100
# )
#
# flow = UserSyncFlow.new(source_connector: source, sink_connector: sink)
# result = flow.execute
#
# if result.success?
#   puts "Sync completed: #{result.value![:stats]}"
# else
#   puts "Sync failed: #{result.failure[:error]}"
# end
#
# # Option 2: Register with ActiveDataFlow for scheduled execution
# UserSyncFlow.register(
#   source_scope: User.active,
#   sink_model: UserBackup,
#   interval: 3600  # Run every hour
# )

# frozen_string_literal: true

module ActiveDataFlow
  class DataFlow < ApplicationRecord
    
    # Associations
    has_many :data_flow_runs, dependent: :destroy
    
    # Validations
    validates :name, presence: true, uniqueness: true
    validates :source, presence: true
    validates :sink, presence: true
    
    # Callbacks
    after_create :schedule_initial_run
    after_update :reschedule_if_needed
    
    # Scopes
    scope :active, -> { where(status: 'active') }
    scope :inactive, -> { where(status: 'inactive') }
    
    # Scope to find flows that have pending runs due to execute
    scope :due_to_run, -> {
      joins(:data_flow_runs)
        .where(status: 'active')
        .where(data_flow_runs: { status: 'pending', run_after: ..Time.current })
        .distinct
    }

    # Tell Rails how to generate routes for this model
    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, ActiveDataFlow, "data_flow")
    end
    
    def self.find_or_create(name:, source:, sink:, runtime:)
      flow = find_or_initialize_by(name: name)
      flow.source = source.as_json
      flow.sink = sink.as_json
      flow.runtime = runtime&.as_json
      flow.status = 'active'
      flow.save!
      flow
    end
    
    def interval_seconds
      runtime&.dig('interval') || 3600
    end
    
    def enabled?
      runtime&.dig('enabled') == true
    end

    def run_one(message)
      transformed = @runtime.transform(message)
      @sink.write(transformed)
      @count += 1
    end

    def run_batch
      @count = 0
      first_id = nil
      last_id = nil
      
      # Pass cursor to source for incremental processing
      @source.each(start_id: next_source_id) do |message|
        # Track cursors
        current_id = message_id(message)
        first_id ||= current_id
        last_id = current_id
        
        run_one(message)
        break if @count >= @runtime.batch_size
      end
      
      # Update cursor on DataFlow to track progress
      if last_id
        update(next_source_id: last_id)
        Rails.logger.info("[DataFlow] Advanced cursor to #{last_id}")
        
        # Also update the run record for tracking
        if current_run = data_flow_runs.in_progress.first
          current_run.update(first_id: first_id, last_id: last_id)
        end
      end
    rescue StandardError => e
      Rails.logger.error("DataFlow error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end

    # Get the next pending run that's due
    def next_due_run
      data_flow_runs.pending.where(run_after: ..Time.current).order(:run_after).first
    end
     
    # Schedule the next run based on interval
    def schedule_next_run(from_time = Time.current)
      return unless enabled?
      
      next_run_time = from_time + interval_seconds.seconds
      data_flow_runs.create!(
        run_after: next_run_time,
        status: 'pending'
      )
    end
    
    # Mark a run as started and schedule the next one
    def mark_run_started!(run)
      run.update!(
        status: 'in_progress',
        started_at: Time.current
      )
      update(last_run_at: Time.current, last_error: nil)
      schedule_next_run
    end
    
    # Mark a run as completed successfully
    def mark_run_completed!(run)
      run.update!(
        status: 'success',
        ended_at: Time.current
      )
    end
    
    # Mark a run as failed
    def mark_run_failed!(run, error)
      run.update!(
        status: 'failed',
        ended_at: Time.current,
        error_message: error.to_s
      )
      update(last_error: error.to_s)
    end
    
    def run
      # Cast to flow_class if needed to ensure we have the correct runtime
      flow_instance = if self.class == ActiveDataFlow::DataFlow && flow_class != ActiveDataFlow::DataFlow
                        becomes(flow_class)
                      else
                        self
                      end
      
      flow_instance.send(:prepare_run)
      flow_instance.run_batch
    end

    def heartbeat_event
      schedule_next_run
    end

    def flow_class
      name.camelize.constantize
    end

    private
    
    def prepare_run
      @source = rehydrate_connector(source)
      @sink = rehydrate_connector(sink)
      @runtime = rehydrate_runtime(runtime)
    end

    def rehydrate_connector(data)
      return nil unless data
      
      klass_name = data['class_name']
      unless klass_name
        Rails.logger.warn "[ActiveDataFlow] Connector class name missing in data: #{data.inspect}"
        return nil
      end
      
      klass = klass_name.constantize
      klass.from_json(data)
    rescue NameError => e
      Rails.logger.error "[ActiveDataFlow] Failed to load connector class: #{e.message}"
      nil
    end
    
    def rehydrate_runtime(data)
      return ActiveDataFlow::Runtime::Base.new unless data
      
      klass_name = data['class_name']
      unless klass_name
        Rails.logger.warn "[ActiveDataFlow] Runtime class name missing in data: #{data.inspect}"
        return ActiveDataFlow::Runtime::Base.new
      end
      
      klass = klass_name.constantize
      klass.from_json(data)
    rescue NameError => e
      Rails.logger.error "[ActiveDataFlow] Failed to load runtime class: #{e.message}"
      ActiveDataFlow::Runtime::Base.new
    end
    
    def schedule_initial_run
      return unless enabled?
      
      # Schedule first run immediately if active
      initial_run_time = status == 'active' ? Time.current : Time.current + interval_seconds.seconds
      data_flow_runs.create!(
        run_after: initial_run_time,
        status: 'pending'
      )
    end
    
    def reschedule_if_needed
      return unless saved_change_to_runtime? || saved_change_to_status?
      
      if status == 'active' && enabled?
        # Cancel any pending runs and schedule a new one
        data_flow_runs.pending.update_all(status: 'cancelled')
        schedule_next_run
      elsif status == 'inactive'
        # Cancel all pending runs
        data_flow_runs.pending.update_all(status: 'cancelled')
      end
    end

    # Override in subclasses to customize message ID extraction
    def message_id(message)
      message['id']
    end

    # Override in subclasses to implement collision detection
    def transform_collision(message, transformed)
      Rails.logger.debug("[DataFlow] Collision detection not implemented for this flow")
      nil
    end

  end
end

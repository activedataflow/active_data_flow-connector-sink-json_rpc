# frozen_string_literal: true

module ActiveDataFlow
  module Redcord
    class DataFlow
      include ::Redcord::Base

      # Schema definition
      attribute :name, :string
      attribute :source, :string  # JSON serialized
      attribute :sink, :string    # JSON serialized
      attribute :runtime, :string # JSON serialized
      attribute :status, :string
      attribute :next_source_id, :string
      attribute :last_run_at, :integer  # Unix timestamp
      attribute :last_error, :string
      attribute :created_at, :integer
      attribute :updated_at, :integer

      # Indexes
      range_index :name
      range_index :status
      range_index :created_at

      # Validations
      validates :name, presence: true, uniqueness: true
      validates :source, presence: true
      validates :sink, presence: true

      # Tell Rails how to generate routes for this model
      def self.model_name
        @_model_name ||= ActiveModel::Name.new(self, ActiveDataFlow, "data_flow")
      end

      def self.find_or_create(name:, source:, sink:, runtime:)
        flow = find_by(name: name) || new
        flow.name = name
        flow.source = source.as_json.to_json
        flow.sink = sink.as_json.to_json
        flow.runtime = runtime&.as_json&.to_json
        flow.status = 'active'
        flow.created_at ||= Time.current.to_i
        flow.updated_at = Time.current.to_i
        flow.save!
        flow
      end

      # Association helpers (Redcord doesn't have built-in associations)
      def data_flow_runs
        ActiveDataFlow::Redcord::DataFlowRun.where(data_flow_id: id)
      end

      # Scopes (implemented as class methods)
      def self.active
        where(status: 'active')
      end

      def self.inactive
        where(status: 'inactive')
      end

      def self.due_to_run
        # Find flows with pending runs that are due
        active_flows = active.to_a
        active_flows.select do |flow|
          flow.data_flow_runs.any? { |run| run.pending? && run.run_after <= Time.current.to_i }
        end
      end

      def interval_seconds
        parsed_runtime&.dig('interval') || 3600
      end

      def enabled?
        parsed_runtime&.dig('enabled') == true
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

        # Pass batch_size and cursor to source for incremental processing
        @source.each(batch_size: @runtime.batch_size, start_id: next_source_id) do |message|
          # Track cursors
          current_id = message_id(message)
          first_id ||= current_id
          last_id = current_id

          run_one(message)
          break if @count >= @runtime.batch_size
        end

        # Update cursor on DataFlow to track progress
        if last_id
          self.next_source_id = last_id
          save!
          Rails.logger.info("[DataFlow] Advanced cursor to #{last_id}")

          # Also update the run record for tracking
          if current_run = data_flow_runs.find { |r| r.in_progress? }
            current_run.first_id = first_id
            current_run.last_id = last_id
            current_run.save!
          end
        end
      rescue StandardError => e
        Rails.logger.error("DataFlow error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise
      end

      # Get the next pending run that's due
      def next_due_run
        data_flow_runs
          .select { |r| r.pending? && r.run_after <= Time.current.to_i }
          .min_by(&:run_after)
      end

      # Schedule the next run based on interval
      def schedule_next_run(from_time = Time.current)
        return unless enabled?

        next_run_time = from_time.to_i + interval_seconds
        ActiveDataFlow::Redcord::DataFlowRun.create!(
          data_flow_id: id,
          run_after: next_run_time,
          status: 'pending',
          created_at: Time.current.to_i,
          updated_at: Time.current.to_i
        )
      end

      # Mark a run as started and schedule the next one
      def mark_run_started!(run)
        run.status = 'in_progress'
        run.started_at = Time.current.to_i
        run.updated_at = Time.current.to_i
        run.save!

        self.last_run_at = Time.current.to_i
        self.last_error = nil
        self.updated_at = Time.current.to_i
        save!

        schedule_next_run
      end

      # Mark a run as completed successfully
      def mark_run_completed!(run)
        run.status = 'success'
        run.ended_at = Time.current.to_i
        run.updated_at = Time.current.to_i
        run.save!
      end

      # Mark a run as failed
      def mark_run_failed!(run, error)
        run.status = 'failed'
        run.ended_at = Time.current.to_i
        run.error_message = error.to_s
        run.updated_at = Time.current.to_i
        run.save!

        self.last_error = error.to_s
        self.updated_at = Time.current.to_i
        save!
      end

      def run
        prepare_run
        run_batch
      end

      def heartbeat_event
        schedule_next_run
      end

      def flow_class
        name.camelize.constantize
      end

      private

      def prepare_run
        @source = rehydrate_connector(parsed_source)
        @sink = rehydrate_connector(parsed_sink)
        @runtime = rehydrate_runtime(parsed_runtime)
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

      # Override in subclasses to customize message ID extraction
      def message_id(message)
        message['id']
      end

      # Override in subclasses to implement collision detection
      def transform_collision(message, transformed)
        Rails.logger.debug("[DataFlow] Collision detection not implemented for this flow")
        nil
      end

      # Helper methods for JSON parsing
      def parsed_source
        source ? JSON.parse(source) : nil
      rescue JSON::ParserError
        nil
      end

      def parsed_sink
        sink ? JSON.parse(sink) : nil
      rescue JSON::ParserError
        nil
      end

      def parsed_runtime
        runtime ? JSON.parse(runtime) : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end

# frozen_string_literal: true

module ActiveDataFlow
  class Sink
    class ActiveRecord < ::ActiveDataFlow::Sink
      attr_reader :config, :model_class, :buffer

      def initialize(config)
        super()
        @config = config
        validate_config!
        @buffer = []
        @model_class = nil
      end

      def write(record)
        if @config[:batch_size]
          @buffer << record
          flush if @buffer.size >= @config[:batch_size]
        else
          write_single(record)
        end
      end

      def flush
        return if @buffer.empty?

        write_batch(@buffer)
        @buffer.clear
      end

      def close
        flush
      end

      private

      def validate_config!
        raise ArgumentError, 'model_name is required' unless @config[:model_name]
      end

      def resolve_model
        @model_class ||= @config[:model_name].to_s.constantize
      rescue NameError => e
        raise ArgumentError, "Invalid model name '#{@config[:model_name]}': #{e.message}"
      end

      def write_single(record)
        if @config[:skip_validations]
          resolve_model.insert(record)
        else
          resolve_model.create!(record)
        end
      rescue ::ActiveRecord::RecordInvalid => e
        handle_error(e, record)
      end

      def handle_error(error, record)
        puts "Error writing record: #{error.message}"
        puts "Record: #{record.inspect}"
        raise error
      end

      def write_batch(records)
        execute_in_transaction do
          if @config[:upsert]
            upsert_options = {}
            upsert_options[:unique_by] = @config[:unique_by] if @config[:unique_by]
            upsert_options[:update_only] = @config[:update_only] if @config[:update_only]
            
            if upsert_options.empty?
              resolve_model.upsert_all(records)
            else
              resolve_model.upsert_all(records, **upsert_options)
            end
          else
            resolve_model.insert_all(records)
          end
        end
      end

      def execute_in_transaction(&block)
        if @config[:transaction]
          resolve_model.transaction(&block)
        else
          yield
        end
      end
    end
  end
end

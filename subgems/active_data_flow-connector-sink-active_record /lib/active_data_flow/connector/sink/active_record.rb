# frozen_string_literal: true

module ActiveDataFlow
  class Source
    class ActiveRecord < ::ActiveDataFlow::Source
      attr_reader :config, :model_class

      def initialize(config)
        super()
        @config = config
        validate_config!
        @model_class = nil
      end

      def each(&block)
        iterate_records(&block)
      end

      def close
        # Release any resources if needed
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

      def build_query
        query = resolve_model.all
        query = query.where(@config[:where]) if @config[:where]
        query = query.order(@config[:order]) if @config[:order]
        query = query.limit(@config[:limit]) if @config[:limit]
        query = query.select(@config[:select]) if @config[:select]
        query = query.includes(@config[:includes]) if @config[:includes]
        query = query.readonly if @config.fetch(:readonly, true)
        query
      end

      def iterate_records(&block)
        if @config[:batch_size]
          build_query.find_each(batch_size: @config[:batch_size], &block)
        else
          build_query.each(&block)
        end
      end
    end
  end
end

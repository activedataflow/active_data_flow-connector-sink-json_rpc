module ActiveDataFlow
  # Base class for all DataFlow objects
  # Provides controller-like functionality and automatic routing
  class DataFlowBase
    class_attribute :flow_configuration
    self.flow_configuration = {}

    class << self
      # DSL for configuring the data flow
      def configure
        self.flow_configuration = {}
        yield(ConfigurationBuilder.new(self))
      end

      # Get the flow name from class name
      def flow_name
        name.underscore
      end

      # Get the route path for this flow
      def route_path
        "/#{flow_name}"
      end

      # Find or create the database record for this flow
      def data_flow_record
        @data_flow_record ||= DataFlowEngine::DataFlow.find_or_create_by(name: flow_name) do |df|
          df.description = flow_configuration[:description] || "DataFlow: #{name}"
          df.configuration = flow_configuration
          df.status = 'draft'
        end
      end

      # Sync with AWS
      def sync!
        data_flow_record.sync!
      end

      # Push configuration to AWS
      def push!
        data_flow_record.push_to_aws
      end

      # Pull configuration from AWS
      def pull!
        data_flow_record.pull_from_aws
      end
    end

    # Instance methods for controller-like actions
    def initialize(params = {})
      @params = params
    end

    # Override in subclasses to define custom actions
    def process
      raise NotImplementedError, "Subclasses must implement #process"
    end

    def status
      {
        name: self.class.flow_name,
        status: self.class.data_flow_record.status,
        aws_sync_status: self.class.data_flow_record.aws_sync_status,
        last_synced_at: self.class.data_flow_record.last_synced_at
      }
    end

    private

    attr_reader :params

    # Configuration builder for DSL
    class ConfigurationBuilder
      def initialize(klass)
        @klass = klass
      end

      def description(value)
        @klass.flow_configuration[:description] = value
      end

      def lambda_function(config)
        @klass.flow_configuration[:lambda_function] = config
      end

      def kafka_topics(topics)
        @klass.flow_configuration[:kafka_topics] = topics
      end

      def kafka_cluster(config)
        @klass.flow_configuration[:kafka_cluster] = config
      end

      def api_gateway(config)
        @klass.flow_configuration[:api_gateway] = config
      end

      def cloudformation_template(template)
        @klass.flow_configuration[:cloudformation_template] = template
      end

      def ecr_repository(config)
        @klass.flow_configuration[:ecr_repository] = config
      end

      def metadata(data)
        @klass.flow_configuration[:metadata] = data
      end
    end
  end
end

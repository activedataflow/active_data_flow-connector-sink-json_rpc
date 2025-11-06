module DataFlowEngine
  class DataFlow < ApplicationRecord
    # Associations
    has_many :lambda_configurations, dependent: :destroy
    has_many :kafka_configurations, dependent: :destroy
    has_many :api_gateway_configurations, dependent: :destroy

    # Validations
    validates :name, presence: true, uniqueness: true
    validates :status, inclusion: { in: %w[draft active inactive] }
    validates :aws_sync_status, inclusion: { in: %w[synced pending error not_synced] }, allow_nil: true

    # Scopes
    scope :active, -> { where(status: 'active') }
    scope :synced, -> { where(aws_sync_status: 'synced') }
    scope :pending_sync, -> { where(aws_sync_status: 'pending') }

    # Callbacks
    before_validation :set_defaults, on: :create
    after_create :initialize_configurations

    # Instance methods
    def push_to_aws
      update(aws_sync_status: 'pending')
      
      result = DataFlowEngine::AwsSyncService.new(self).push
      
      if result[:success]
        update(
          aws_sync_status: 'synced',
          last_synced_at: Time.current,
          metadata: metadata.merge(last_push: result[:details])
        )
      else
        update(
          aws_sync_status: 'error',
          metadata: metadata.merge(last_error: result[:error])
        )
      end
      
      result
    end

    def pull_from_aws
      update(aws_sync_status: 'pending')
      
      result = DataFlowEngine::AwsSyncService.new(self).pull
      
      if result[:success]
        update(
          aws_sync_status: 'synced',
          last_synced_at: Time.current,
          metadata: metadata.merge(last_pull: result[:details])
        )
      else
        update(
          aws_sync_status: 'error',
          metadata: metadata.merge(last_error: result[:error])
        )
      end
      
      result
    end

    def sync!
      # Perform bidirectional sync
      pull_result = pull_from_aws
      return pull_result unless pull_result[:success]
      
      push_to_aws
    end

    def sync_status
      {
        name: name,
        status: status,
        aws_sync_status: aws_sync_status,
        last_synced_at: last_synced_at,
        has_lambda: lambda_configurations.any?,
        has_kafka: kafka_configurations.any?,
        has_api_gateway: api_gateway_configurations.any?
      }
    end

    def activate!
      update(status: 'active')
    end

    def deactivate!
      update(status: 'inactive')
    end

    private

    def set_defaults
      self.status ||= 'draft'
      self.aws_sync_status ||= 'not_synced'
      self.configuration ||= {}
      self.metadata ||= {}
    end

    def initialize_configurations
      # Create associated configurations based on the configuration hash
      if configuration['lambda_function'].present?
        lambda_configurations.create(
          function_name: "#{name}_lambda",
          code_language: configuration['lambda_function']['code_language'] || 'ruby',
          runtime: configuration['lambda_function']['runtime'] || 'ruby3.2',
          handler: configuration['lambda_function']['handler'] || 'handler.process',
          memory_size: configuration['lambda_function']['memory_size'] || 512,
          timeout: configuration['lambda_function']['timeout'] || 30,
          environment_variables: configuration['lambda_function']['environment_variables'] || {}
        )
      end

      if configuration['kafka_topics'].present? || configuration['kafka_cluster'].present?
        kafka_configurations.create(
          cluster_name: "#{name}_kafka_cluster",
          topics: configuration['kafka_topics'] || [],
          broker_configuration: configuration['kafka_cluster'] || {}
        )
      end

      if configuration['api_gateway'].present?
        api_gateway_configurations.create(
          api_name: configuration['api_gateway']['api_name'] || "#{name}_api",
          stage_name: configuration['api_gateway']['stage_name'] || 'production',
          routes: configuration['api_gateway']['routes'] || []
        )
      end
    end
  end
end

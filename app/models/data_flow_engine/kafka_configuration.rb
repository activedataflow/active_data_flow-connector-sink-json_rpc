module DataFlowEngine
  class KafkaConfiguration < ApplicationRecord
    # Associations
    belongs_to :data_flow

    # Validations
    validates :cluster_name, presence: true

    # Callbacks
    before_validation :set_defaults, on: :create

    # Scopes
    scope :deployed, -> { where.not(cluster_arn: nil) }

    # Instance methods
    def create_cluster
      service = DataFlowEngine::KafkaService.new(self)
      result = service.create_cluster
      
      if result[:success]
        update(cluster_arn: result[:cluster_arn])
      end
      
      result
    end

    def create_topics
      return { success: false, error: 'Cluster not deployed' } unless deployed?
      
      service = DataFlowEngine::KafkaService.new(self)
      service.create_topics
    end

    def update_cluster_config(new_config)
      update(broker_configuration: new_config)
      
      if deployed?
        service = DataFlowEngine::KafkaService.new(self)
        service.update_cluster
      end
    end

    def deployed?
      cluster_arn.present?
    end

    def topic_names
      topics.is_a?(Array) ? topics : []
    end

    def add_topic(topic_name)
      current_topics = topic_names
      current_topics << topic_name unless current_topics.include?(topic_name)
      update(topics: current_topics)
      
      create_topics if deployed?
    end

    def remove_topic(topic_name)
      current_topics = topic_names
      current_topics.delete(topic_name)
      update(topics: current_topics)
    end

    private

    def set_defaults
      self.topics ||= []
      self.broker_configuration ||= {
        'instance_type' => 'kafka.m5.large',
        'number_of_broker_nodes' => 3,
        'kafka_version' => '3.5.1'
      }
    end
  end
end

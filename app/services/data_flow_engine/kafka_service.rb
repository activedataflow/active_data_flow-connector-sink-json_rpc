require 'aws-sdk-kafka'

module DataFlowEngine
  class KafkaService
    attr_reader :kafka_configuration

    def initialize(kafka_configuration)
      @kafka_configuration = kafka_configuration
      @client = Aws::Kafka::Client.new
    end

    # Create MSK cluster
    def create_cluster
      broker_config = kafka_configuration.broker_configuration

      response = @client.create_cluster({
        cluster_name: kafka_configuration.cluster_name,
        kafka_version: broker_config['kafka_version'] || '3.5.1',
        number_of_broker_nodes: broker_config['number_of_broker_nodes'] || 3,
        broker_node_group_info: {
          instance_type: broker_config['instance_type'] || 'kafka.m5.large',
          client_subnets: get_subnet_ids,
          security_groups: get_security_group_ids,
          storage_info: {
            ebs_storage_info: {
              volume_size: broker_config['volume_size'] || 100
            }
          }
        },
        encryption_info: {
          encryption_in_transit: {
            client_broker: 'TLS',
            in_cluster: true
          }
        },
        enhanced_monitoring: 'DEFAULT',
        tags: {
          'ManagedBy' => 'ActiveDataFlow',
          'DataFlow' => kafka_configuration.data_flow.name
        }
      })

      {
        success: true,
        cluster_arn: response.cluster_arn,
        cluster_name: response.cluster_name,
        state: response.state
      }
    rescue Aws::Kafka::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Update cluster configuration
    def update_cluster
      return { success: false, error: 'Cluster not deployed' } unless kafka_configuration.deployed?

      broker_config = kafka_configuration.broker_configuration

      response = @client.update_broker_storage({
        cluster_arn: kafka_configuration.cluster_arn,
        current_version: get_current_cluster_version,
        target_broker_ebs_volume_info: [
          {
            kafka_broker_node_id: 'ALL',
            volume_size: broker_config['volume_size'] || 100
          }
        ]
      })

      {
        success: true,
        cluster_arn: response.cluster_arn
      }
    rescue Aws::Kafka::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Create Kafka topics
    def create_topics
      return { success: false, error: 'Cluster not deployed' } unless kafka_configuration.deployed?

      # Get bootstrap brokers
      brokers_response = @client.get_bootstrap_brokers({
        cluster_arn: kafka_configuration.cluster_arn
      })

      bootstrap_servers = brokers_response.bootstrap_broker_string_tls

      # In production, this would use the Kafka Admin API to create topics
      # For now, we'll return a success response with the topic information
      {
        success: true,
        topics: kafka_configuration.topic_names,
        bootstrap_servers: bootstrap_servers,
        message: 'Topics configuration prepared. Use Kafka Admin API to create topics.'
      }
    rescue Aws::Kafka::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get cluster information
    def get_cluster_info
      return { success: false, error: 'Cluster not deployed' } unless kafka_configuration.deployed?

      response = @client.describe_cluster({
        cluster_arn: kafka_configuration.cluster_arn
      })

      cluster_info = response.cluster_info

      {
        success: true,
        cluster_info: {
          cluster_arn: cluster_info.cluster_arn,
          cluster_name: cluster_info.cluster_name,
          state: cluster_info.state,
          kafka_version: cluster_info.current_broker_software_info.kafka_version,
          number_of_broker_nodes: cluster_info.number_of_broker_nodes,
          zookeeper_connect_string: cluster_info.zookeeper_connect_string
        }
      }
    rescue Aws::Kafka::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get bootstrap brokers
    def get_bootstrap_brokers
      return { success: false, error: 'Cluster not deployed' } unless kafka_configuration.deployed?

      response = @client.get_bootstrap_brokers({
        cluster_arn: kafka_configuration.cluster_arn
      })

      {
        success: true,
        bootstrap_broker_string: response.bootstrap_broker_string,
        bootstrap_broker_string_tls: response.bootstrap_broker_string_tls
      }
    rescue Aws::Kafka::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Delete cluster
    def delete_cluster
      return { success: false, error: 'Cluster not deployed' } unless kafka_configuration.deployed?

      response = @client.delete_cluster({
        cluster_arn: kafka_configuration.cluster_arn
      })

      {
        success: true,
        cluster_arn: response.cluster_arn,
        state: response.state
      }
    rescue Aws::Kafka::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    private

    # Get subnet IDs from configuration or environment
    def get_subnet_ids
      # In production, these should come from configuration or be created
      ENV['MSK_SUBNET_IDS']&.split(',') || ['subnet-12345', 'subnet-67890', 'subnet-abcde']
    end

    # Get security group IDs
    def get_security_group_ids
      # In production, these should come from configuration or be created
      ENV['MSK_SECURITY_GROUP_IDS']&.split(',') || ['sg-12345']
    end

    # Get current cluster version for updates
    def get_current_cluster_version
      response = @client.describe_cluster({
        cluster_arn: kafka_configuration.cluster_arn
      })
      response.cluster_info.current_version
    end
  end
end

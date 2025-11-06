module DataFlowEngine
  class DataFlowsController < ApplicationController
    before_action :set_data_flow, only: [:show, :update, :destroy, :sync, :push, :pull, :status]

    # GET /dataflow
    def index
      @data_flows = DataFlow.all
      render_success(
        data_flows: @data_flows.map { |df| data_flow_summary(df) }
      )
    end

    # GET /dataflow/:id
    def show
      render_success(
        data_flow: data_flow_detail(@data_flow)
      )
    end

    # POST /dataflow
    def create
      @data_flow = DataFlow.new(data_flow_params)

      if @data_flow.save
        render_success(
          data_flow: data_flow_detail(@data_flow),
          message: 'DataFlow created successfully'
        ), status: :created
      else
        render_error(@data_flow.errors.full_messages.join(', '))
      end
    end

    # PATCH/PUT /dataflow/:id
    def update
      if @data_flow.update(data_flow_params)
        render_success(
          data_flow: data_flow_detail(@data_flow),
          message: 'DataFlow updated successfully'
        )
      else
        render_error(@data_flow.errors.full_messages.join(', '))
      end
    end

    # DELETE /dataflow/:id
    def destroy
      @data_flow.destroy
      render_success(message: 'DataFlow deleted successfully')
    end

    # POST /dataflow/:id/sync
    def sync
      result = @data_flow.sync!
      
      if result[:success]
        render_success(
          message: 'Sync completed successfully',
          sync_result: result
        )
      else
        render_error(result[:error], status: :internal_server_error)
      end
    end

    # POST /dataflow/:id/push
    def push
      result = @data_flow.push_to_aws
      
      if result[:success]
        render_success(
          message: 'Push to AWS completed successfully',
          push_result: result
        )
      else
        render_error(result[:error], status: :internal_server_error)
      end
    end

    # POST /dataflow/:id/pull
    def pull
      result = @data_flow.pull_from_aws
      
      if result[:success]
        render_success(
          message: 'Pull from AWS completed successfully',
          pull_result: result
        )
      else
        render_error(result[:error], status: :internal_server_error)
      end
    end

    # GET /dataflow/:id/status
    def status
      render_success(
        status: @data_flow.sync_status
      )
    end

    private

    def set_data_flow
      @data_flow = DataFlow.find_by(id: params[:id]) || DataFlow.find_by(name: params[:id])
      
      unless @data_flow
        render_error('DataFlow not found', status: :not_found)
      end
    end

    def data_flow_params
      params.require(:data_flow).permit(
        :name,
        :description,
        :status,
        configuration: {},
        metadata: {}
      )
    end

    def data_flow_summary(data_flow)
      {
        id: data_flow.id,
        name: data_flow.name,
        description: data_flow.description,
        status: data_flow.status,
        aws_sync_status: data_flow.aws_sync_status,
        last_synced_at: data_flow.last_synced_at,
        created_at: data_flow.created_at,
        updated_at: data_flow.updated_at
      }
    end

    def data_flow_detail(data_flow)
      data_flow_summary(data_flow).merge(
        configuration: data_flow.configuration,
        metadata: data_flow.metadata,
        lambda_configurations: data_flow.lambda_configurations.map { |lc| lambda_config_summary(lc) },
        kafka_configurations: data_flow.kafka_configurations.map { |kc| kafka_config_summary(kc) },
        api_gateway_configurations: data_flow.api_gateway_configurations.map { |agc| api_gateway_config_summary(agc) }
      )
    end

    def lambda_config_summary(lambda_config)
      {
        id: lambda_config.id,
        function_name: lambda_config.function_name,
        code_language: lambda_config.code_language,
        runtime: lambda_config.runtime,
        handler: lambda_config.handler,
        memory_size: lambda_config.memory_size,
        timeout: lambda_config.timeout,
        aws_function_arn: lambda_config.aws_function_arn,
        deployed: lambda_config.deployed?
      }
    end

    def kafka_config_summary(kafka_config)
      {
        id: kafka_config.id,
        cluster_name: kafka_config.cluster_name,
        cluster_arn: kafka_config.cluster_arn,
        topics: kafka_config.topic_names,
        deployed: kafka_config.deployed?
      }
    end

    def api_gateway_config_summary(api_gateway_config)
      {
        id: api_gateway_config.id,
        api_name: api_gateway_config.api_name,
        api_id: api_gateway_config.api_id,
        stage_name: api_gateway_config.stage_name,
        endpoint_url: api_gateway_config.endpoint_url,
        deployed: api_gateway_config.deployed?
      }
    end
  end
end

# frozen_string_literal: true

module ActiveDataFlow
  class DataFlowRunsController < ApplicationController
    before_action :set_data_flow_run, only: [:show]
    before_action :set_data_flow, only: [:index, :create]

    def index
      @data_flow_runs = @data_flow.data_flow_runs
                                  .includes(:data_flow)
                                  .order(created_at: :desc)
                                  .page(params[:page])
                                  .per(20)
    end

    def show
    end

    def create
      @data_flow_run = @data_flow.data_flow_runs.build(data_flow_run_params)
      
      if @data_flow_run.save
        redirect_to [@data_flow, @data_flow_run], notice: 'Data flow run was successfully scheduled.'
      else
        redirect_to @data_flow, alert: 'Failed to schedule data flow run.'
      end
    end

    private

    def set_data_flow_run
      @data_flow_run = DataFlowRun.find(params[:id])
    end

    def set_data_flow
      @data_flow = DataFlow.find(params[:data_flow_id])
    end

    def data_flow_run_params
      params.require(:data_flow_run).permit(:run_after, :metadata)
    end
  end
end
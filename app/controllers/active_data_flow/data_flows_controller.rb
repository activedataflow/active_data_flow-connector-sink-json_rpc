# frozen_string_literal: true

module ActiveDataFlow
  class DataFlowsController < ApplicationController
    before_action :set_data_flow, only: [:show, :trigger]

    def index
      @data_flows = DataFlow.all
    end

    def show
    end

    def trigger
      # TODO: Implement actual data flow execution
      @data_flow.update(last_run_at: Time.current)
      redirect_to data_flow_path(@data_flow), notice: "Data flow triggered successfully"
    end

    private

    def set_data_flow
      @data_flow = DataFlow.find(params[:id])
    end
  end
end

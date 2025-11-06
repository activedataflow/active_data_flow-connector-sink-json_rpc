require 'rails_helper'

RSpec.describe DataFlowEngine::DataFlow, type: :model do
  describe 'associations' do
    it { should have_many(:lambda_configurations).dependent(:destroy) }
    it { should have_many(:kafka_configurations).dependent(:destroy) }
    it { should have_many(:api_gateway_configurations).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active inactive]) }
  end

  describe 'scopes' do
    let!(:active_flow) { create(:data_flow, :active) }
    let!(:draft_flow) { create(:data_flow) }
    let!(:synced_flow) { create(:data_flow, :synced) }

    it 'returns active flows' do
      expect(described_class.active).to include(active_flow)
      expect(described_class.active).not_to include(draft_flow)
    end

    it 'returns synced flows' do
      expect(described_class.synced).to include(synced_flow)
      expect(described_class.synced).not_to include(draft_flow)
    end
  end

  describe '#push_to_aws' do
    let(:data_flow) { create(:data_flow) }
    let(:sync_service) { instance_double(DataFlowEngine::AwsSyncService) }

    before do
      allow(DataFlowEngine::AwsSyncService).to receive(:new).and_return(sync_service)
    end

    context 'when push is successful' do
      before do
        allow(sync_service).to receive(:push).and_return({
          success: true,
          details: { lambda: [{ status: 'deployed' }] }
        })
      end

      it 'updates sync status to synced' do
        data_flow.push_to_aws
        expect(data_flow.reload.aws_sync_status).to eq('synced')
      end

      it 'updates last_synced_at' do
        expect { data_flow.push_to_aws }.to change { data_flow.reload.last_synced_at }
      end
    end

    context 'when push fails' do
      before do
        allow(sync_service).to receive(:push).and_return({
          success: false,
          error: 'AWS error'
        })
      end

      it 'updates sync status to error' do
        data_flow.push_to_aws
        expect(data_flow.reload.aws_sync_status).to eq('error')
      end
    end
  end

  describe '#sync_status' do
    let(:data_flow) { create(:data_flow, :with_lambda, :with_kafka) }

    it 'returns comprehensive status information' do
      status = data_flow.sync_status

      expect(status).to include(:name, :status, :aws_sync_status)
      expect(status[:has_lambda]).to be true
      expect(status[:has_kafka]).to be true
    end
  end

  describe '#activate!' do
    let(:data_flow) { create(:data_flow) }

    it 'changes status to active' do
      expect { data_flow.activate! }.to change { data_flow.status }.from('draft').to('active')
    end
  end
end

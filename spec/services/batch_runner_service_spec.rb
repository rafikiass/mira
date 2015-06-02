require 'spec_helper'

describe BatchRunnerService do
  let(:runner) { described_class.new(batch) }

  describe '#run' do
    subject { runner.run }

    context "when the batch is not valid" do
      let(:batch) { BatchPurge.new }
      it { is_expected.to be false }
    end

    context "with multiple pids" do
      let(:batch) { build(:batch_revert, pids: [7, 8]) }

      it 'queues a job for each pid and saves the job ids' do
        expect(Job::Revert).to receive(:create).with(user_id: batch.creator.id, batch_id: batch.id, record_id: 7) { :a }
        expect(Job::Revert).to receive(:create).with(user_id: batch.creator.id, batch_id: batch.id, record_id: 8) { :b }
        expect(subject).to be true
        expect(batch.job_ids).to eq [:a, :b]
      end
    end

  end
end


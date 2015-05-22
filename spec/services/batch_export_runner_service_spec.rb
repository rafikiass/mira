require 'spec_helper'

describe BatchExportRunnerService do

  let(:datastream_ids) { %w(DCA-META DCA-DETAIL-META DCA-ADMIN RELS-EXT) }
  let(:runner) { described_class.new(batch, datastream_ids) }

  describe '#run' do
    subject { runner.run }

    context "when the batch is not valid" do
      let(:batch) { BatchExport.new }
      it { is_expected.to be false }
    end

    context "with a batch export" do
      let(:batch) { FactoryGirl.build(:batch_export, pids: ['tufts:123', 'tufts:456']) }

      let(:runner) { described_class.new(batch, datastream_ids) }

      it 'creates a single Job::Export with the correct args' do
        expect(Job::Export).to receive(:create).with({
          user_id: batch.creator.id,
          batch_id: batch.id,
          record_ids: ['tufts:123', 'tufts:456'],
          datastream_ids: datastream_ids
        }).once { :a }

        expect(subject).to be true
      end

      it 'sets the batches job_ids to a one-element list' do
        allow(Job::Export).to receive(:create).once { :a }

        expect(subject).to be true

        expect(batch.job_ids).to eq([:a])
      end
    end
  end
end


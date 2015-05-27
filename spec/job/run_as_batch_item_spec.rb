require 'spec_helper'

module Job
  class MyJob
    include RunAsBatchItem
  end
end


describe Job::RunAsBatchItem do
  let(:user) { FactoryGirl.create(:user) }
  let(:batch) { Batch.create(creator: user) }

  describe '#run_as_batch_item' do
    let(:old_batch_id) { '456' }
    let(:batch_id) { batch.id }
    let(:old_status) { 'some existing status message' }
    let(:pdf) { FactoryGirl.create(:tufts_pdf, batch_id: [old_batch_id], qrStatus: [Reviewable.batch_review_text, old_status]) }

    let(:job) { Job::MyJob.new }

    after { pdf.delete }

    it 'yields the record' do
      yielded = job.run_as_batch_item(pdf.id, batch_id) do |record|
        record.pid
      end
      expect(yielded).to eq pdf.pid
    end

    it 'adds batch id to the object without removing existing batch ids' do
      job.run_as_batch_item(pdf.id, batch_id) do |record|
        record.save!
      end
      pdf.reload
      expect(pdf.batch_id).to eq [old_batch_id, batch_id.to_s]
    end

    it 'sets the working_user on the record so that the audit logs will contain the user key' do
      job.run_as_batch_item(pdf.id, batch_id) do |record|
        expect(record.working_user).to eq user
      end
    end
  end

end

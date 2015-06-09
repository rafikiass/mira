require 'spec_helper'

describe Job::Import do
  let(:record) { TuftsPdf.new(pid: 'tufts:123') }
  let(:job) { described_class.new('uuid', 'user_id' => 456,
                                  'record_id' => 'tufts:123', 'batch_id' => 1010) }
  let(:service) { double('import service') }
  let(:batch) { Batch::MetadataImport.new(id: 1010) }

  before do
    allow(Batch).to receive(:find).with(1010).and_return(batch)
    allow(ActiveFedora::Base).to receive(:find).with('tufts:123', cast: true).and_return(record)
  end

  it 'publishes the record' do
    expect(ImportService).to receive(:new).with(record: record, batch: batch).and_return(service)
    expect(service).to receive(:run)
    job.perform
    expect(record.batch_id).to eq ['1010']
  end
end

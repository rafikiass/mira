require 'spec_helper'

describe Job::Import do
  let(:record) { double(id: 'tufts:123') }
  let(:job) { described_class.new('uuid', 'user_id' => 456,
                                  'record_id' => 'tufts:123', 'batch_id' => 1010) }
  let(:service) { double }

  it 'publishes the record' do
    expect(ImportService).to receive(:new).with(pid: record.id, batch_id: 1010).and_return(service)
    expect(service).to receive(:run)
    job.perform
  end
end

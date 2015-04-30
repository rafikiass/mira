require 'spec_helper'

describe Job::RegisterHandle do

  it 'uses the "handle" queue' do
    expect(described_class.queue).to eq :handle
  end

  describe '::create' do
    let(:opts) do
      { record_id: '1' }
    end

    it 'requires the record id' do
      opts.delete(:record_id)
      expect{described_class.create(opts)}.to raise_exception(ArgumentError, /record_id/)
    end
  end

  describe '#perform' do
    let(:service) { double }
    let(:job) { described_class.new('uuid', 'record_id' => 'tufts:1') }

    it 'raises an error if it fails to find the object' do
      expect(RegisterHandleService).to receive(:new).with('tufts:1').and_return(service)
      expect(service).to receive(:run)
      job.perform
    end
  end
end

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

    context "when the object exists" do
      let(:object) { double }
      before do
        allow(ActiveFedora::Base).to receive(:find).with('tufts:1').and_return(object)
      end
      it 'calls the service' do
        expect(RegisterHandleService).to receive(:new).with(object).and_return(service)
        expect(service).to receive(:run)
        job.perform
      end
    end

    context "when the object doesn't exist" do
      before do
        ActiveFedora::Base.find('tufts:1').delete if ActiveFedora::Base.exists?('tufts:1')
      end
      it 'raises an error' do
        expect {
          job.perform
        }.to raise_error ActiveFedora::ObjectNotFoundError
      end
    end
  end
end

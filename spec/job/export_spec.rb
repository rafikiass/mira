require 'spec_helper'

describe Job::Export do

  it 'uses the :export queue' do
    expect(Job::Export.queue).to eq(:export)
  end

  describe 'Job::Export.create' do

    let(:options) {
      {
        record_ids: ['tufts:123', 'tufts:456'],
        user_id: '1',
        batch_id: '1',
        datastream_ids: %w(DCA-META)
      }
    }

    it 'can be created with default options' do
      job = described_class.create(options)
      expect(job).to_not be_nil
    end

    it 'requires the user id' do
      options.delete(:user_id)
      expect { described_class.create(options) }.to raise_exception(ArgumentError, /user_id/)
    end

    it 'requires the record id' do
      options.delete(:record_ids)
      expect { described_class.create(options) }.to raise_exception(ArgumentError, /record_ids/)
    end

    it 'requires datastream_ids' do
      options.delete(:datastream_ids)
      expect { described_class.create(options) }.to raise_exception(ArgumentError, /datastream_ids/)
    end

    it 'requires the batch id' do
      options.delete(:batch_id)
      expect { described_class.create(options) }.to raise_exception(ArgumentError, /batch_id/)
    end

  end

  describe '#perform' do
    let(:user) { FactoryGirl.create(:user) }
    let(:job) {
      Job::Export.new('uuid', {
        'user_id' => 1,
        'record_ids' => ['tufts:123', 'tufts:456'],
        'datastream_ids' => %w(DCA-META DCA-META-ADMIN),
        'batch_id' => 42
      })
    }

    it 'creates an instance of DraftExportService' do
      expect(DraftExportService).to receive(:new).with({
        record_ids: ['tufts:123', 'tufts:456'],
        datastream_ids: %w(DCA-META DCA-META-ADMIN),
        batch_id: 42
      }) { double('fake-service').as_null_object }

      job.perform
    end

    it 'calls run on the service' do
      mock_service = double('fake-export-service')
      expect(mock_service).to receive(:run).once

      allow(DraftExportService).to receive(:new) { mock_service }

      job.perform
    end

    it 'works without mocking' do
      job.perform
    end

  end

end

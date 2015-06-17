require 'spec_helper'

describe ImportService do
  before do
    ActiveFedora::Base.find('draft:12440').delete if ActiveFedora::Base.exists?('draft:12440')
  end

  let!(:object) { TuftsImage.create(pid: 'draft:12440', displays: ['tisch'], title: 'foo') }

  let(:file) { File.open(fixture_path + '/export/sample_export.xml').read }
  let(:batch) { Batch::MetadataImport.new(id: 999, metadata_file: file) }

  let(:service) { described_class.new(record: object, batch: batch) }


  it "replaces the datastreams" do
    service.run
    object.reload

    expect(object.title).to eq 'test image'
  end

  context "batch_ids" do
    it "uses the batch_ids from the import as the baseline" do
      object.batch_id = %w(444 555 666)

      object.save
      service.run
      object.reload

      expect(object.batch_id).to eq(%w(321 999))
    end
  end
end

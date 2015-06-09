require 'spec_helper'

describe ImportService do
  before do
    ActiveFedora::Base.find('draft:12440').delete if ActiveFedora::Base.exists?('draft:12440')
  end

  let!(:object) { TuftsImage.create(pid: 'draft:12440', displays: ['tisch'], title: 'foo') }

  let(:service) { described_class.new(record: object, batch: batch) }
  let(:file) { File.open(fixture_path + '/export/sample_export.xml').read }
  let(:batch) { Batch::MetadataImport.new(id: 999, metadata_file: file) }


  it "replaces the datastreams" do
    service.run
    object.reload
    expect(object.title).to eq 'test image'
  end
end

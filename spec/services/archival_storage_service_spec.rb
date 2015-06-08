require 'spec_helper'

describe ArchivalStorageService do
  let(:object_class) { TuftsPdf }
  let(:object) { object_class.new(pid: 'tufts:1234') }
  let(:dsid) { object_class.default_datastream }
  let(:file) { Rack::Test::UploadedFile.new(File.join('spec', 'fixtures', 'hello.pdf'), 'application/pdf') }
  let(:service) { described_class.new(object, dsid, file) }
  let(:datastream) { object.datastreams[dsid] }
  let(:pid) { PidUtils.stripped_pid(object.pid) }

  it "stores the file" do
    expect { service.run }.to change { datastream.dsLocation }.from(nil).
      to("http://bucket01.lib.tufts.edu/data01/tufts/sas/archival_pdf/#{pid}.archival.pdf")
  end

  context "when the object is a TuftsGenericObject" do
    let(:object_class) { TuftsGenericObject }
    let(:dsid) { 'GENERIC-CONTENT' }
    it "stores the file and writes a manifest" do
      service.run
      expect(datastream.item.fileName).to eq ['hello.pdf']
      expect(datastream.item.link).to eq ['http://bucket01.lib.tufts.edu/data01/tufts/sas/1234/generic/1234.pdf']
      expect(datastream.item.mimeType).to eq ['application/pdf']
    end
  end
end

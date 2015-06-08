require 'spec_helper'

describe GenericObjectArchivalStorageService do
  let(:object_class) { TuftsGenericObject }
  let(:object) { object_class.new(pid: 'tufts:1234') }
  let(:dsid) { 'GENERIC-CONTENT' }
  let(:file) { Rack::Test::UploadedFile.new(File.join('spec', 'fixtures', 'hello.pdf'), 'application/pdf') }
  let(:datastream) { object.datastreams[dsid] }
  let(:service) { described_class.new(object, dsid, file) }
  let(:pid) { PidUtils.stripped_pid(object.pid) }

  it "stores the file with the original name and writes a manifest" do
    service.run
    expect(datastream.item.fileName).to eq ['hello.pdf']
    expect(datastream.item.link).to eq ['http://bucket01.lib.tufts.edu/data01/tufts/sas/1234/generic/hello.pdf']
    expect(datastream.item.mimeType).to eq ['application/pdf']
  end
end

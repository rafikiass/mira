require 'spec_helper'

describe GenericObjectArchivalStorageService do
  let(:object_class) { TuftsGenericObject }
  let(:object) { object_class.new(pid: 'tufts:1234') }
  let(:dsid) { 'GENERIC-CONTENT' }
  let(:file) { Rack::Test::UploadedFile.new(File.join('spec', 'fixtures', 'hello.pdf'), 'application/pdf') }
  let(:datastream) { object.datastreams[dsid] }
  let(:service) { described_class.new(object, dsid, file) }
  let(:pid) { PidUtils.stripped_pid(object.pid) }

  it "stores the file and creates a job to write the manifest" do
    expect(Job::ManifestUpdate).to receive(:create).with(pid: 'tufts:1234', filename: 'hello.pdf', link: 'http://bucket01.lib.tufts.edu/data01/tufts/sas/1234/generic/hello.pdf', mime_type: 'application/pdf')
    service.run
  end
end

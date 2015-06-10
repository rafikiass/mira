require 'spec_helper'

describe ArchivalStorageService do
  let(:object_class) { TuftsPdf }
  let(:object) { object_class.new(pid: 'tufts:1234') }
  let(:dsid) { object_class.default_datastream }
  let(:file) { Rack::Test::UploadedFile.new(File.join('spec', 'fixtures', 'hello.pdf'), 'application/pdf') }
  let(:service) { described_class.new(object, dsid, file) }
  let(:datastream) { object.datastreams[dsid] }
  let(:pid) { PidUtils.stripped_pid(object.pid) }

  before do
    datastream.checksum = 'abcdef1234'
  end

  it "stores the file" do
    expect { service.run }.to change { datastream.dsLocation }.from(nil).
      to("http://bucket01.lib.tufts.edu/data01/tufts/sas/archival_pdf/#{pid}.archival.pdf").
    and change { datastream.checksum }.to(nil)
  end

end

require 'spec_helper'

describe ArchivalStorageService do
  let(:object_class) { TuftsPdf }
  let(:object) { object_class.new(pid: 'draft:1234', displays: ['dl'], title: 'something') }
  let(:dsid) { object_class.default_datastream }
  let(:file) { Rack::Test::UploadedFile.new(File.join('spec', 'fixtures', 'hello.pdf'), 'application/pdf') }
  let(:service) { described_class.new(object, dsid, file) }
  let(:datastream) { object.datastreams[dsid] }
  let(:pid) { PidUtils.stripped_pid(object.pid) }

  before do
    datastream.checksum = 'abcdef1234'
  end

  context "when no file exists" do
    it "stores the file" do
      expect { service.run }.to change { datastream.dsLocation }.from(nil).
        to("file://#{Rails.root}/spec/fixtures/local_object_store/data01/tufts/sas/archival_pdf/#{pid}.archival.pdf").
      and change { datastream.checksum }.to(nil).
      and change { datastream.dsLabel  }.to('hello.pdf')
    end
  end

  context "with an existing file" do

    let(:old_file) { Rack::Test::UploadedFile.new(File.join('spec', 'fixtures', 'hello2.pdf'), 'application/pdf') }

    before do
      described_class.new(object, dsid, old_file).run
      object.save!
    end

    context "when the object has been published" do
      let!(:prod_version) { PublishService.new(object).run }

      it "clears the checksum on the published version" do
        service.run
        expect(prod_version.datastreams[dsid].checksum).to eq '5a2d761cab7c15b2b3bb3465ce64586d'
      end
    end

  end
end

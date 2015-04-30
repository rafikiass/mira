require 'spec_helper'

describe RegisterHandleService do
  let(:object) { TuftsPdf.build_draft_version(displays: ['dl'], title: "orig title") }
  let(:service) { described_class.new(object) }
  let(:file_name) { 'tmp/handle/handles-1234567890.txt' }

  before { File.unlink(file_name) if File.exists?(file_name) }

  # TODO It must record the identifier on the draft and production versions of the object.
  describe "#run" do

    subject { service.run }
    before { allow_any_instance_of(RegisterHandleService::BatchFileGenerator).to receive(:file_name).and_return(file_name) }
    before do
      allow(service).to receive(:run_command).and_return(message)
    end

    context "when there is an error registering the handle" do
      let(:message) { "Start Time: Thu Apr 30 16:20:29 UTC 2015\n==>FAILURE[7]: create:10427.TEST/123456: Error(101): HANDLE ALREADY EXISTS\nSuccesses/Total Entries: 0/1\nBatch File Lines: 7\nFinish Time: Thu Apr 30 16:20:30 UTC 2015\nThis batch took 0 seconds to complete at an average speed of 4.464285714285714 operations/second\n" }

      it "makes a batch file" do
        expect { subject }.to raise_error RegisterHandleService::HandleServiceError, "Unable to register handle 10427.TEST/000001 for #{object.pid}\n#{message}"
        expect(object.identifier).to be_blank
      end
    end

    context "when the handle registers" do
      before { object.save!; PublishService.new(object).run }
      let(:published_version) { object.find_published }
      let(:message) { "success" }

      let(:batch_file) do
        "AUTHENTICATE PUBKEY:300:0.NA/10427.TEST\n" +
        "/hs/srv_2/admpriv.bin|SOMEKEY\n\n" +
        "CREATE 10427.TEST/000001\n" +
        "2 URL 86400 1110 UTF8 http://dl.tufts.edu/catalog/#{object.pid}\n\n"
      end

      it "makes a batch file" do
        expect { subject }.to change {
          File.exists?(file_name) }.from(false).to(true)

        expect(object.identifier).to_not be_blank
        expect(File.read(file_name)).to eq batch_file
        expect(object).to be_published # ensure we haven't changed the status

        expect(published_version.identifier).to_not be_blank
        expect(published_version).to be_published # ensure we haven't changed the status
      end
    end
  end
end

require 'spec_helper'

describe RegisterHandleService do
  let(:object) { TuftsPdf.new(pid: 'draft:1', displays: ['dl'], title: "orig title") }
  let(:service) { described_class.new(object) }

  describe "#url" do
    subject { service.send(:url) }
    it "is a production url" do
      expect(subject).to eq "http://dl.tufts.edu/catalog/tufts:1"
    end
  end
  describe "#build_record" do
    subject { service.send(:build_record, 'hdl/hdl1') }
    let(:batch) { subject.to_batch }
    it "has the necessary metadata" do
      expect(batch[0]).to eq "2 URL 86400 1110 UTF8 http://dl.tufts.edu/catalog/tufts:1"
      expect(batch[1]).to eq "6 EMAIL 86400 1110 UTF8 brian.goodmon@tufts.edu"
      expect(batch[2]).to eq "100 HS_ADMIN 86400 1110 ADMIN 300:111111111111:0.NA/10427.TEST"
    end
  end


  describe "#run" do

    context "when there is an error registering the handle" do
      before do
        allow_any_instance_of(Handle::Record).to receive(:save).and_raise Handle::HandleError.new('Invalid admin')
        allow(service).to receive(:generate_handle).and_return 'hdl/hdl1'
      end

      subject { service.run }

      it "logs errors and re-raises" do
        expect(HandleLogService).to receive(:log).with(nil, object.pid, "Unable to register handle hdl/hdl1 for draft:1\nInvalid admin")
        expect { subject }.to raise_error Handle::HandleError, "Invalid admin"
        expect(object.identifier).to be_blank
      end
    end

    context "when the service runs" do

      context "and there is a published version" do
        before { object.save!; PublishService.new(object).run }
        let!(:published_version) { object.find_published }
        it "registers a handle" do
          expect_any_instance_of(Handle::Record).to receive(:save).and_return(true)
          service.run
          expect(object.identifier).to_not be_blank
          expect(object).to be_published # ensure we haven't changed the status
          expect(published_version.identifier).to_not be_blank
          expect(published_version).to be_published # ensure we haven't changed the status
        end
      end

      context "and there isn't a published version" do
        before { object.save! }

        it "registers a handle" do
          expect_any_instance_of(Handle::Record).to receive(:save).and_return(true)
          service.run
          expect(object.identifier).to eq ['http://hdl.handle.net/10427.TEST/000001']
          expect(object).not_to be_published # ensure we haven't changed the status
        end
      end
    end
  end
end

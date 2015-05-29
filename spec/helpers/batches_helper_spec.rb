require 'spec_helper'

describe BatchesHelper do
  before { @record = FactoryGirl.create(:tufts_pdf) }
  after  { @record.delete }

  describe 'for batch types that run jobs' do
    let(:batch) { FactoryGirl.create(:batch_publish, pids: [@record.pid]) }
    let(:job) do
      double({"time" => 1397575745,
              "uuid" => "1234",
              "status" => "queued",
              "options" => {"user_id" => 2,
                            "record_id" => @record.pid,
                            "batch_id" => batch.id }})
    end

    after { batch.delete }

    it '#line_item_status displays the job status' do
      status = helper.line_item_status(batch, job)
      expect(status).to match /queued/i
    end

    it '#item_count displays the number of jobs' do
      allow(batch).to receive(:job_ids) { [job.uuid] }
      expect(helper.item_count(batch)).to eq 1
    end

    context "when the status isn't available" do
      let(:job) { nil }

      it '#line_item_status says the status is expired' do
        status = helper.line_item_status(batch, job)
        expect(status).to eq "Status not available"
      end
    end
  end

  describe "for batch types that don't run jobs" do
    let(:batch) { FactoryGirl.create(:batch_template_import, pids: [@record.pid]) }

    describe '#line_item_status' do
      it 'displays the record status' do
        status = helper.line_item_status(batch, nil, @record.pid)
        expect(status).to match /completed/i
      end

      it "has a default value if it can't figure out status" do
        pid = 'tufts:1'
        ActiveFedora::Base.find(pid).destroy if ActiveFedora::Base.exists?(pid)
        status = helper.line_item_status(batch, nil, pid)
        expect(status).to match /Status not available/i
      end

      it 'rescues and returns default value' do
        allow(ActiveFedora::Base).to receive(:exists?).and_raise(Rubydora::FedoraInvalidRequest.new)
        status = helper.line_item_status(batch, nil, 'tufts:1')
        expect(status).to match /Status not available/i
      end
    end

    describe '#item_count' do
      subject { helper.item_count(batch) }
      it { is_expected.to eq 1 }

      context "when pids is empty" do
        let(:batch) { BatchTemplateUpdate.new }
        it { is_expected.to eq 0 }
      end
    end
  end

  describe "#batch_action_button" do
    subject { batch_action_button(title, path, batch, options) }
    let(:title) { 'Batch Stuff' }
    let(:path) { '/things' }
    let(:batch) { double(pids: ['tufts:1', 'tufts:2']) }
    let(:options) { { data: { confirm: 'really?' } } }

    it "draws the form" do
      expect(subject).to have_selector 'form[action="/things"]'
      expect(subject).to have_selector 'input[type=submit][value="Batch Stuff"][data-confirm="really?"]'
      expect(subject).to have_selector 'input[type=hidden][name="pids[]"][value="tufts:1"]'
      expect(subject).to have_selector 'input[type=hidden][name="pids[]"][value="tufts:2"]'
    end
  end
end

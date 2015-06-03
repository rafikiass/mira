require 'spec_helper'

describe BatchesHelper do
  before { @record = FactoryGirl.create(:tufts_pdf) }
  after  { @record.delete }

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

  describe "#batch_export_download_link" do
    let(:batch) { mock_model(BatchExport, id: 42) }
    subject { batch_export_download_link(batch) }

    context "when the batch's status is :completed" do
      before do
        allow(batch).to receive(:status) { :completed }
      end

      it "links to the download action" do
        expect(subject).to eq("<a href=\"http://test.host/batch/exports/42/download\">batch_42.xml</a>")
      end
    end

    context "when the batches status is not :completed" do
      before do
        allow(batch).to receive(:status) { :not_available }
      end

      it "shows the 'waiting' message" do
        expect(subject).to eq("XML file will be available for download when export is complete")
      end
    end


  end
end

require 'spec_helper'

describe "batch/xml_imports/show.html.erb" do

  let(:creator) { mock_model(User, display_name: 'bob') }

  describe 'a batch with no pids' do
    let(:batch) { mock_model(BatchXmlImport, pids: [], missing_files:[], display_name: 'foo', creator: creator, status: :queued) }
    before do
      assign :batch, batch
      assign :records_by_pid, {}
    end

    it "displays gracefully" do
      expect { render }.to_not raise_error
    end
  end

  describe 'apply_template' do
    let(:batch) { mock_model(BatchXmlImport, pids: records.map(&:pid), missing_files: [],
                             display_name: 'howdy', jobs: jobs,
                             creator: creator, status: batch_status, pid: 'tufts:123') }
    let(:pdf) { mock_model(TuftsPdf, pid: 'tufts:234', title: 'A pdf') }
    let(:records) { [pdf] }
    let(:records_by_pid) { { records[0].pid => records[0] } }
    let(:batch_status) { :queued }
    let(:jobs) do
      records.zip(0.upto(records.length)).map do |r, uuid|
        double('uuid' => uuid,
             'status' => 'queued',
             'options' => {'record_id' => r.pid})
      end
    end
    let(:line_item_status) { 'Queued' }

    before do
      allow(Resque::Plugins::Status::Hash).to receive(:get) do |uuid|
        jobs.find{|j| j.uuid == uuid}
      end
      allow(view).to receive(:line_item_status).and_return(line_item_status)
      assign :batch, batch
      assign :records_by_pid, records_by_pid
      render
    end

    it "shows batch information" do
      expect(rendered).to have_selector(".type", text: batch.display_name)
      expect(rendered).to have_selector(".batch_id", text: batch.id)
      expect(rendered).to have_selector(".record_count", text: records.count)
      expect(rendered).to have_selector(".creator", text: batch.creator.display_name)
      expect(rendered).to have_selector(".created_at", text: batch.created_at)
      expect(rendered).to have_selector(".status", text: 'Queued')
      expect(rendered).to have_link(records.first.pid, catalog_path(records.first))
      expect(rendered).to have_selector(".record_title", text: records.first.title)
      expect(rendered).to have_selector(".record_status", text: "Queued")
    end

    context "with missing records" do
      it "should render successfully" do
        pid = records.first.pid
        records.first.destroy
        render
        expect(rendered).to have_selector(".record_pid", text: pid)
      end
    end

    context "with some records reviewed" do
      let(:records) do
        d1 = mock_model(TuftsAudio, pid: 'tufts:456', title: 'another one', reviewed?: true)
        [d1, pdf]
      end
      let(:records_by_pid) { { records[0].pid => records[0], records[1].pid => records[1] } }

      it "shows review status of each record" do
        expect(rendered).to have_selector(".review_status", text: "Incomplete")
        expect(rendered).to have_selector(".record_reviewed_status input[type=checkbox][disabled=disabled][checked=checked]")
        expect(rendered).to have_selector(".record_reviewed_status input[type=checkbox][disabled=disabled]:not([checked=checked])")
      end
    end

    context "with all records reviewed" do
      let(:records) do
        [mock_model(TuftsAudio, pid: 'tufts:456', title: 'another one', reviewed?: true)]
      end

      it "shows an complete reviewed status" do
        expect(rendered).to have_selector(".review_status", text: "Complete")
      end
    end

    context "with nil statuses on a recent batch" do
      let(:batch_status) { :not_available }
      let(:line_item_status) { 'Status not available' }
      it 'says statuses are not availble' do
        expect(rendered).to have_selector(".batch_info .status", text: "Status not available")
        expect(rendered).to have_selector(".record_status", text: "Status not available")
      end
    end

    context "with nil statuses on an old batch" do
      let(:line_item_status) { 'Status expired' }
      let(:batch_status) { :not_available }

      it 'shows the status' do
        expect(rendered).to have_selector(".batch_info .status", text: "Status not available")
        expect(rendered).to have_selector(".record_status", text: "Status expired")
      end
    end
  end
end

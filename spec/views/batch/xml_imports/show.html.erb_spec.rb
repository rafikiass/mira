require 'spec_helper'

describe "batch/xml_imports/show.html.erb" do

  let(:batch) { mock_model(BatchXmlImport, pids: [], missing_files:[], display_name: 'foo', creator: creator, status: batch_status) }
  let(:batch_status) { :queued }

  let(:creator) { mock_model(User, display_name: 'bob') }
  let(:presenter) { XmlImportPresenter.new(batch) }
  before do
    allow(presenter).to receive(:items) { items }
    allow(view).to receive(:resource) { presenter }
  end

  describe 'a XmlImportPresenter with no items' do
    let(:items) { [] }
    it "displays gracefully" do
      expect { render }.to_not raise_error
    end
  end

  describe 'apply_template' do
    let(:pdf) { mock_model(TuftsPdf, pid: 'tufts:234', title: 'A pdf') }
    let(:items) { [item_status] }
    let(:dsid) { 'Archival.pdf' }
    let(:filename) { 'my_upload.pdf' }
    let(:item_status) { XmlImportItemStatus.new(batch, pdf.pid, dsid, filename) }
    let(:line_item_status) { 'Completed' }

    before do
      allow(item_status).to receive(:status).and_return(line_item_status)
      allow(item_status).to receive(:reviewed?).and_return(true)
    end

    it "shows batch information" do
      render
      expect(rendered).to have_selector(".type", text: batch.display_name)
      expect(rendered).to have_selector(".batch_id", text: batch.id)
      expect(rendered).to have_selector(".record_count", text: '0')
      expect(rendered).to have_selector(".creator", text: batch.creator.display_name)
      expect(rendered).to have_selector(".created_at", text: batch.created_at)
      expect(rendered).to have_selector(".status", text: 'Queued')
      expect(rendered).to have_link('tufts:234', catalog_path('tufts:234'))
      expect(rendered).to have_selector(".record_title", text: 'my_upload.pdf')
      expect(rendered).to have_selector(".record_status", text: "Completed")
    end

    context "with some records reviewed" do
      let(:items) { [item_status, reviewed_item] }
      let(:reviewed_item) { XmlImportItemStatus.new(batch, 'tufts:9999', 'archival.pdf', 'hello.pdf') }
      let(:alt_record) { mock_model TuftsPdf, pid: 'tufts:9999', title: "Another doc" }
      before do
        allow(presenter).to receive(:review_status) { 'Incomplete' }
        allow(reviewed_item).to receive(:record).and_return(alt_record)
        allow(reviewed_item).to receive(:status).and_return('Complete')
        allow(reviewed_item).to receive(:reviewed?) { true }
        allow(item_status).to receive(:reviewed?) { false }
        render
      end

      it "shows review status of each record" do
        expect(rendered).to have_selector(".review_status", text: "Incomplete")
        expect(rendered).to have_selector(".record_reviewed_status input[type=checkbox][disabled=disabled][checked=checked]")
        expect(rendered).to have_selector(".record_reviewed_status input[type=checkbox][disabled=disabled]:not([checked=checked])")
      end
    end

    context "with all records reviewed" do
      before do
        allow(presenter).to receive(:review_status) { 'Complete' }
        allow(item_status).to receive(:status).and_return('Complete')
        allow(item_status).to receive(:review_status) { true }
        render
      end

      it "shows an complete reviewed status" do
        expect(rendered).to have_selector(".review_status", text: "Complete")
      end
    end

    context "with nil statuses on a recent batch" do
      let(:batch_status) { :not_available }
      let(:line_item_status) { 'Status not available' }
      it 'says statuses are not availble' do
        render
        expect(rendered).to have_selector(".batch_info .status", text: "Status not available")
        expect(rendered).to have_selector(".record_status", text: "Status not available")
      end
    end

    context "with nil statuses on an old batch" do
      let(:line_item_status) { 'Status expired' }
      let(:batch_status) { :not_available }

      it 'shows the status' do
        render
        expect(rendered).to have_selector(".batch_info .status", text: "Status not available")
        expect(rendered).to have_selector(".record_status", text: "Status expired")
      end
    end

    context 'a batch with missing files' do
      let(:missing_file) { 'missing_file.pdf' }
      let(:batch) { mock_model(BatchXmlImport, pids: [], missing_files: [missing_file], display_name: 'howdy', creator: creator, status: batch_status, pid: 'tufts:123') }

      it 'it displays the list of missing files' do
        render
        expect(rendered).to have_selector('li', text: missing_file)
      end
    end
  end
end

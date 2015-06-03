require 'spec_helper'

describe "batches/show.html.erb" do

  let(:batch) { mock_model BatchPublish, pids: [], job_ids: [4567], creator: creator,
                display_name: 'This is a batch', status: batch_status }
  let(:batch_status) { :queued }
  let(:creator) { mock_model User, display_name: 'Mike K.' }
  let(:presenter) { BatchPresenter.new(batch) }
  before do
    allow(presenter).to receive(:items) { items }
    allow(view).to receive(:resource) { presenter }
  end

  describe 'a BatchPresenter with no items' do
    let(:items) { [] }

    it "displays gracefully" do
      expect { render }.to_not raise_error
    end
  end

  describe 'apply_template' do
    let(:pdf) { mock_model TuftsPdf, pid: 'tufts:234', title: "A PDF doc" }
    let(:items) { [item_status] }
    let(:item_status) { BatchItemStatus.new(batch, pdf.pid) }

    let(:line_item_status) { 'Queued' }

    before do
      allow(item_status).to receive(:record).and_return(pdf)
      allow(item_status).to receive(:status).and_return(line_item_status)
    end

    it "shows batch information" do
      render
      expect(rendered).to have_selector(".type", text: "This is a batch")
      expect(rendered).to have_selector(".batch_id", text: batch.id)
      expect(rendered).to have_selector(".record_count", text: 1)
      expect(rendered).to have_selector(".creator", text: "Mike K.")
      expect(rendered).to have_selector(".created_at", text: batch.created_at)
      expect(rendered).to have_selector(".status", text: 'Queued')

      expect(rendered).to have_link(pdf.pid, catalog_path(pdf))
      expect(rendered).to have_selector(".record_title", text: pdf.title)
      expect(rendered).to have_selector(".record_status", text: "Queued")
    end

    context "with some records reviewed" do
      let(:items) { [item_status, reviewed_item] }
      let(:reviewed_item) { BatchItemStatus.new(batch, 'tufts:9999') }
      let(:alt_record) { mock_model TuftsPdf, pid: 'tufts:9999', title: "Another doc" }
      before do
        allow(presenter).to receive(:review_status) { 'Incomplete' }
        allow(reviewed_item).to receive(:record).and_return(alt_record)
        allow(reviewed_item).to receive(:status).and_return('Complete')
        allow(reviewed_item).to receive(:review_status) { true }
        allow(item_status).to receive(:review_status) { false }
      end

      it "shows a complete reviewed status" do
        render
        expect(rendered).to have_selector(".review_status", text: "Incomplete")
        expect(rendered).to have_selector(".record_reviewed_status input[type=checkbox][disabled=disabled][checked=checked]")
        expect(rendered).to have_selector(".record_reviewed_status input[type=checkbox][disabled=disabled]:not([checked=checked])")
      end
    end

    context "with all records reviewed" do
      before { allow(presenter).to receive(:review_status) { 'Complete' } }

      it "shows an complete reviewed status" do
        render
        expect(rendered).to have_selector(".review_status", text: "Complete")
      end
    end

    context "with nil statuses on a recent batch" do
      let(:batch_status) { :not_available }
      let(:line_item_status) { 'Status not available' }

      it 'says the batch status is not availble' do
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
  end
end

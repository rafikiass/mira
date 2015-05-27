require 'spec_helper'

describe "batches/index.html.erb" do
  let(:creator) { mock_model(User, display_name: 'bob') }
  let(:batch1) { mock_model(BatchTemplateUpdate, pids: [], missing_files:[], display_name: 'foo', creator: creator, status: :completed, created_at: 2.days.ago, job_ids: [1, 2]) }
  let(:batch2) { mock_model(BatchTemplateImport, pids: [], missing_files:[], display_name: 'foo', creator: creator, status: :completed, created_at: 4.days.ago) }
  let(:batches) { [batch1, batch2] }

  before do
    assign :batches, batches
    expect(view).to receive(:paginate) { 'pagination links' }
    render
  end

  it "shows a list of batches" do
    batches.each do |batch|
      expect(rendered).to have_selector('.batch_id', text: batch.id)
      expect(rendered).to have_selector('.display_name', text: batch.display_name)
      expect(rendered).to have_selector('.creator', text: batch.creator.display_name)
      expect(rendered).to have_selector(".created_at", text: time_ago_in_words(batch.created_at))
      expect(rendered).to have_selector(".status", text: 'Completed')
    end
    expect(rendered).to have_selector(".item_count", text: 2)
    expect(rendered).to have_selector(".item_count", text: 0)
  end
end

require 'spec_helper'

describe 'batches/_batch_actions.html.erb' do
  let(:batch) { mock_model(BatchXmlImport, pids: ['tufts:1', 'tufts:2'],
                           status: batch_status) }
  let(:presenter) { XmlImportPresenter.new(batch) }

  before do
    render 'batches/batch_actions', batch: presenter
  end

  context 'a batch with status "completed"' do
    let(:batch_status) { :completed }

    it 'displays the form to operate on the batch' do
      expect(rendered).to have_link('Review Batch', href: catalog_index_path(search_field: 'batch', q: batch.id.to_s))

      #button to publish
      expect(rendered).to have_selector("form[method=post][action='#{batch_publishes_path}'] " +
           "input[type=submit][value='Publish Batch']")

      #button to unpublish
      expect(rendered).to have_selector("form[method=post][action='#{batch_unpublishes_path}'] " +
          "input[type=submit][value='Unpublish Batch']")

      #button to purge
      expect(rendered).to have_selector("form[method=post][action='#{batch_purges_path}'] " +
          "input[type=submit][value='Purge Batch']")

      #button to revert
      expect(rendered).to have_selector("form[method=post][action='#{batch_reverts_path}'] " +
          "input[type=submit][value='Revert Batch']")

      #hidden pids
      expect(rendered).to have_selector("form[method=post][action='#{batch_reverts_path}'] " +
          "input[type=hidden][name='pids[]'][value='tufts:1']")
      expect(rendered).to have_selector("form[method=post][action='#{batch_reverts_path}'] " +
          "input[type=hidden][name='pids[]'][value='tufts:2']")
    end
  end

  context 'a batch status that is anything but "completed"' do
    let(:batch_status) { :queued }

    it 'disables the batch operation buttons' do
      expect(rendered).to have_selector("input[type=submit][value='Publish Batch'][disabled=disabled]")
      expect(rendered).to have_selector("input[type=submit][value='Unpublish Batch'][disabled=disabled]")
      expect(rendered).to have_selector("a[href='#{catalog_index_path(search_field: 'batch', q: batch.id.to_s)}'][disabled]", text: 'Review Batch')
    end
  end
end

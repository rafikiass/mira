require 'spec_helper'

describe "batches/edit.html.erb" do
  let(:creator) { mock_model(User, display_name: 'bob') }
  let(:batch) { mock_model(BatchTemplateImport, pids: [], missing_files:[], display_name: 'foo', creator: creator, status: :queued) }

  before do
    assign :batch, batch
  end

  describe 'form to upload files' do
    before { render }

    it 'has the selectors needed for the javascript' do
      @selectors = ['form#fileupload', '#select_files', '#next_button']
      @selectors.each do |s|
        expect(rendered).to have_selector(s)
      end
    end

    it 'has input fields' do
      expect(rendered).to have_selector("input[type=file][name='documents[]'][multiple=multiple]")
      expect(rendered).to have_selector("button[type=submit]")
    end

  end

end

require 'spec_helper'

describe "batch/xml_imports/edit.html.erb" do
  let(:creator) { mock_model(User, display_name: 'bob') }
  let(:batch) { mock_model(BatchXmlImport, pids: [], missing_files:[], display_name: 'foo', creator: creator, status: :queued) }

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

  describe "the list of missing files" do
    before do
      allow(batch).to receive(:missing_files) { %w(A B C a b c) }
      render
    end

    it "displays them in a specific sorted order" do
      expect(rendered).to have_selector('ul.missing_files li:nth-child(1)', 'A')
      expect(rendered).to have_selector('ul.missing_files li:nth-child(2)', 'a')
      expect(rendered).to have_selector('ul.missing_files li:nth-child(3)', 'B')
      expect(rendered).to have_selector('ul.missing_files li:nth-child(4)', 'b')
      expect(rendered).to have_selector('ul.missing_files li:nth-child(5)', 'C')
      expect(rendered).to have_selector('ul.missing_files li:nth-child(6)', 'c')
    end

  end

end

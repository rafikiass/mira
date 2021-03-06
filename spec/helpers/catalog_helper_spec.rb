require 'spec_helper'

describe CatalogHelper do
  describe 'link_to_edit' do
    let(:draft_pid) { 'draft:123' }
    let(:edit_path) { link_to 'Edit Metadata', HydraEditor::Engine.routes.url_helpers.edit_record_path(draft_pid) }
    let(:solr_doc) { SolrDocument.new(id: pid) }

    context 'for a draft object' do
      let(:pid) { draft_pid }

      it 'returns the edit link' do
        expect(helper.link_to_edit(solr_doc)).to eq edit_path
      end
    end

    context 'for a non-draft object' do
      let(:pid) { 'tufts:123' }

      it 'returns the link to edit the draft object' do
        expect(helper.link_to_edit(solr_doc)).to eq edit_path
      end
    end
  end


  describe 'workflow_status_indicator' do
    let(:document) { double('fake-document', workflow_status: "some-workflow-status") }
    let(:options) { {} }

    subject { workflow_status_indicator(document, options) }

    it 'has the documents workflow status as the class and content'  do
      expect(subject).to eq('<span class="workflow-status some-workflow-status">some-workflow-status</span>')
    end

    context 'with a :class option' do
      let(:options) {
        { class: "extra-markup" }
      }

      it "should include the extra class in the wrapper span" do
        expect(subject).to eq('<span class="workflow-status some-workflow-status extra-markup">some-workflow-status</span>')
      end
    end
  end

end

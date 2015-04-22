require 'spec_helper'

describe 'catalog/_show_tools.html.erb' do
  before do
    allow(view).to receive(:can?) { true }
    assign :document, doc
  end
  let(:doc) { SolrDocument.new(id: 'pid:1') }

  it 'displays a link to the attached files' do
    render
    expect(rendered).to have_link('Manage Datastreams', href: record_attachments_path(doc))
  end

  context "when the document is a template" do
    let(:doc) { SolrDocument.new(id: 'pid:1', active_fedora_model_ssi: 'TuftsTemplate') }
    it 'disables link to the attached files for a template' do
      render
      expect(rendered).to have_link('Manage Datastreams', href: '#')
    end
  end

  describe "the review link" do
    context "when the document is reviewable" do
      before { expect(doc).to receive(:reviewable?).and_return(true) }

      it 'displays a link to mark the object as reviewed' do
        render
        expect(rendered).to have_link('Mark as Reviewed', href: review_record_path(doc))
      end
    end

    context "when the document is reviewable" do
      before { allow(doc).to receive(:reviewable?) { false } }

      it 'disables the review link if object is not reviewable' do
        render
        expect(rendered).to have_link('Mark as Reviewed', href: '#')
      end
    end
  end

  describe "the publish/unpublish controls" do
    context "when the document is publishable" do
      before { allow(doc).to receive(:publishable?) { true } }

      it 'displays the publish link' do
        render
        expect(rendered).to have_link('Publish', href: publish_record_path(doc))
        expect(rendered).not_to have_link('Unpublish')
      end
    end

    context "when the document is published" do
      before do
        allow(doc).to receive(:publishable?) { false }
        allow(doc).to receive(:published?) { true }
      end

      it 'displays the unpublish' do
        render
        expect(rendered).to have_link('Unpublish', href: unpublish_record_path(doc))
        expect(rendered).not_to have_link('Publish')
      end
    end
  end
end

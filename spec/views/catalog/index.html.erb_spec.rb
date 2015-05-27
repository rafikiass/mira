require 'spec_helper'

describe 'catalog/index.html.erb' do
  before do
    @document_list = [SolrDocument.new(id: 'some_id', active_fedora_model_ssi: 'TuftsImage')]
    {current_user: double(admin?: true),
      has_search_parameters?: false,
      render_grouped_response?: false,
      blacklight_config: CatalogController.new.blacklight_config,
      render_index_doc_actions: '',
      search_session: {},
      current_search_session: nil
    }.each do |m, result|
      allow(view).to receive(m) { result }
    end
    # allow(Deprecation).to receive(:silence)
    stub_template 'catalog/_search_sidebar.html.erb' => '',
      'catalog/_search_header.html.erb' => '',
      'catalog/_results_pagination.html.erb' => ''
    assign :response, double(:response, empty?: false, params: {}, total: 0, start: 0, limit_value: 10)
  end

  context 'viewing search results' do
    before do
      allow(view).to receive(:has_search_parameters?) { true }
    end

    describe 'checkboxes' do
      before do
        render
      end
      it 'has a box to select all documents' do
        expect(rendered).to have_selector("input#check_all[type=checkbox]")
      end
      it 'lets you select individual documents' do
        expect(rendered).to have_selector("input.batch_document_selector[type=checkbox][name='batch[pids][]'][value='#{@document_list.first.id}']")
      end
    end

    describe 'batch operations' do
      it 'draws the form with required fields' do
        render
        expect(rendered).to have_selector("form[method=post][action='#{batches_path}']")

        #sends the form page as a hidden field
        expect(rendered).to have_selector("input[type=hidden][name='batch_form_page'][value='1']")

        #button to apply a template
        expect(rendered).to have_selector("button[type=submit][name='batch[type]'][value=BatchTemplateUpdate][data-behavior=batch-create]")

        #button to publish
        expect(rendered).to have_selector("button[type=submit][name='batch[type]'][value=BatchPublish][data-behavior=batch-create]")

        #button to unpublish
        expect(rendered).to have_selector("button[type=submit][name='batch[type]'][value=BatchUnpublish][data-behavior=batch-create]")

        #button to revert
        expect(rendered).to have_selector("button[type=submit][name='batch[type]'][value=BatchRevert][data-behavior=batch-create]")

        # the div needed by javascript to display the number of documents that are currently selected
        expect(rendered).to have_selector("#selected_documents_count")
      end
    end

    describe 'with a document that is an image' do
      before do
        @document_list = [SolrDocument.new(id: 'id2', has_model_ssim: ['fedora/cm:Image.4DS'])]
        render
      end

      it 'displays thumbnails' do
        src = download_path(@document_list.first.id, datastream_id: 'Thumbnail.png')
        expect(rendered).to have_selector("#documents .document-thumbnail img[src='#{src}']")
      end
    end
  end

  context 'workflow_status' do
    before do
      allow(view).to receive(:has_search_parameters?) { true }
    end

    describe 'for drafts' do
      before do
        earlier = "2015-01-01 12:00:00"
        later =  "2015-01-01 13:00:00"
        @document_list = [SolrDocument.new(id: 'pub', active_fedora_model_ssi: 'TuftsImage', edited_at_dtsi: earlier, published_at_dtsi: earlier),
                          SolrDocument.new(id: 'unpub', active_fedora_model_ssi: 'TuftsImage', edited_at_dtsi: earlier, published_at_dtsi: nil),
                          SolrDocument.new(id: 'ed', active_fedora_model_ssi: 'TuftsImage', edited_at_dtsi: later, published_at_dtsi: earlier)
                          ]
        render
      end

      it 'displays status tags' do
        expect(rendered).to have_selector(".unpublished", count: 1)
        expect(rendered).to have_selector(".published", count: 1)
        expect(rendered).to have_selector(".edited", count: 1)
      end
    end

    it 'handles production objects gracefully' do
      @document_list = [SolrDocument.new(id: 'tufts:prod', has_model_ssim: ['fedora/cm:Image.4DS'])]
      # These shouldn't end up in the document list from the catalog controller, but make sure the applications behaves reasonable if they do
      render
      expect(rendered).to have_selector(".published")
    end
  end

end

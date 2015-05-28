require 'spec_helper'

describe 'unpublished/index.html.erb' do

  before do
    assign :response, double(:response, empty?: false, params: {}, total: 0, start: 0, limit_value: 10)

    { current_user: double(admin?: true),
      render_grouped_response?: false,
      blacklight_config: UnpublishedController.new.blacklight_config,
      search_session: {},
      current_search_session: nil,
      controller: double(is_a?: true, params: {})
    }.each do |m, result|
      allow(view).to receive(m) { result }
    end

    stub_template '_facets.html.erb' => '',
                  '_did_you_mean.html.erb' => '',
                  '_constraints.html.erb' => '',
                  '_sort_and_per_page.html.erb' => '',
                  '_results_pagination.html.erb' => ''

    @document_list = [SolrDocument.new(id: 'some_id', active_fedora_model_ssi: 'TuftsImage')]
  end

  describe 'batch operations' do
    before { render }

    it 'displays the button to publish' do
      expect(rendered).to have_selector("form[method=post][action='#{batch_publishes_path}'] input[type=submit][value=Publish][data-behavior=batch-create]")

      # not the unpublish button
      expect(rendered).to_not have_selector("input[type=submit][value=Unpublish]")
    end
  end
end

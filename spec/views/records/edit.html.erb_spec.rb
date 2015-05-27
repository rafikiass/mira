require 'spec_helper'

describe 'records/edit.html.erb' do
  before do
    stub_template 'records/_form.html.erb' => ''
    allow(view).to receive(:resource).and_return(resource)
    render
  end

  context 'for a non-template' do
    let(:resource) { double(title: 'My Document', has_thumbnail?: false, id: 'pid:123', to_solr: {}) }

    it "displays the object's title" do
      expect(rendered).to have_content('Edit My Document')
    end
    it 'does not link to the index' do
      expect(rendered).to_not have_link('Index of Templates', href: templates_path)
    end
  end

  context "when object is a template" do
    let(:resource) { mock_model(TuftsTemplate, template_name: 'My Template', title: 'My Document', has_thumbnail?: false, id: 'pid:123', to_solr: {}) }

    it "displays the template_name" do
      expect(rendered).to have_content('Edit My Template')
    end
    it 'links to the index' do
      expect(rendered).to have_link('Index of Templates', href: templates_path)
    end
  end
end

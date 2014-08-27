require 'spec_helper'

describe 'records/edit.html.erb' do

  let(:resource) { double(title: 'My Document', has_thumbnail?: false, id: 'pid:123', to_solr: {}) }

  before do
    allow(view).to receive(:resource).and_return(resource)
  end

  describe 'the page title' do
    before do
      stub_template 'records/_form.html.erb' => ''
    end

    it "displays the object's title" do
      render
      expect(rendered).to have_content('Edit My Document')
    end

    context "when object is a template" do
      let(:resource) { double(template_name: 'My Template', title: 'My Document', has_thumbnail?: false, id: 'pid:123', to_solr: {}) }

      it "displays the template_name" do
        expect(resource).to receive(:is_a?).with(TuftsTemplate) { true }
        render
        expect(rendered).to have_content('Edit My Template')
      end
    end
  end


  describe 'Link to template index' do
    before { stub_template 'records/_form.html.erb' => '' }

    context "when object is a template" do
      let(:resource) { double(template_name: 'My Template', title: 'My Document', has_thumbnail?: false, id: 'pid:123', to_solr: {}) }

      it 'is displayed if the object is a template' do
        expect(resource).to receive(:is_a?).with(TuftsTemplate) { true }
        render
        expect(rendered).to have_link('Index of Templates', href: templates_path)
      end
    end

    it 'is not displayed if the object is not a template' do
      render
      expect(rendered).to_not have_link('Index of Templates', href: templates_path)
    end
  end

  describe 'relationship fields' do
    let(:resource) { FactoryGirl.create(:tufts_pdf) }
    after { resource.destroy }

    before do
      render
    end

    it 'contains selectors needed for the javascript' do
      expect(rendered).to have_selector('#additional_relationship_attributes_clone')
      expect(rendered).to have_selector('#additional_relationship_attributes_elements')
      expect(rendered).to have_selector('#additional_relationship_attributes_clone button.adder')
    end
  end

end

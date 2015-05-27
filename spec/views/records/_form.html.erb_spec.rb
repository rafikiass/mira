require 'spec_helper'

describe 'records/_form.html.erb' do
  # let(:resource) { mock_model TuftsPdf, pid: 'tufts:123', state: 'A' }
  let(:resource) { build(:tufts_pdf) }
  let(:dca_meta) { double(versions: []) }

  before do
    allow(resource).to receive(:to_param).and_return('tufts:123')
    allow(resource).to receive(:DCA_META).and_return(dca_meta)
    allow(view).to receive(:resource).and_return(resource)
    render
  end

  it 'contains selectors needed for the javascript' do
    expect(rendered).to have_selector('#additional_relationship_attributes_clone')
    expect(rendered).to have_selector('#additional_relationship_attributes_elements')
    expect(rendered).to have_selector('#additional_relationship_attributes_clone button.adder')
  end
end

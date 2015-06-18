require 'spec_helper'

describe 'catalog/_export_datastream_form.html.erb' do
  it 'has the expected datastream fields named properly' do
    render

    expect(rendered).to have_selector('input[name="datastream_ids[]"][value="DCA-META"]')
    expect(rendered).to have_selector('input[name="datastream_ids[]"][value="DC-DETAIL-META"]')
    expect(rendered).to have_selector('input[name="datastream_ids[]"][value="DCA-ADMIN"]')
    expect(rendered).to have_selector('input[name="datastream_ids[]"][value="RELS-EXT"]')
  end
end


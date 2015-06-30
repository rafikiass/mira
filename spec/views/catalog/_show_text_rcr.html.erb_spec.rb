require 'spec_helper'

describe 'catalog/_show_text_rcr.html.erb' do

  let(:doc) { double('fake-solr-doc', id: '123') }

  before do
    stub_template 'catalog/_show_default.html.erb' => ''
    allow(view).to receive(:document) { doc }

    render
  end

  it 'has the download link for RCR-CONTENT' do
    url = download_path(doc.id, datastream_id: 'RCR-CONTENT')

    expect(rendered).to have_selector("a[href='#{url}']", text: "Download")
  end

end

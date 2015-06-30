require 'spec_helper'

describe 'catalog/_show_text_pdf.html.erb' do

  let(:doc) { SolrDocument.new(id: 'tufts:1', displays_ssim: ['dl'], edited_at_dtsi: 'some date', published_at_dtsi: nil) }

  before do
    stub_template 'catalog/_show_default.html.erb' => ''

    expect(doc).to receive(:has_datastream_content?).with('Archival.pdf') { true }
    expect(doc).to receive(:has_datastream_content?).with('Transfer.binary') { true }
    expect(doc).to receive(:transfer_binary_filename) { 'foo.zip' }

    allow(view).to receive(:document) { doc }

    render
  end

  it 'has the download link for Archival.pdf' do
    url = download_path(doc.id, datastream_id: 'Archival.pdf')

    expect(rendered).to have_selector("a[href='#{url}']", text: "Download Archival.pdf")
  end

  it 'has the download link for Transfer.binary' do
    url = download_path(doc.id, datastream_id: 'Transfer.binary')

    expect(rendered).to have_selector("a[href='#{url}']", text: "Download foo.zip")
  end

end

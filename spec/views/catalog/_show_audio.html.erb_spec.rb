require 'spec_helper'

describe 'catalog/_show_audio.html.erb' do
  let(:doc) { SolrDocument.new(id: 'tufts:1', displays_ssim: ['dl'], edited_at_dtsi: 'some date', published_at_dtsi: nil) }

  before do
    stub_template 'catalog/_show_default.html.erb' => ''

    allow(view).to receive(:can?) { true }
    allow(view).to receive(:document) { doc }
    allow(doc).to receive(:has_datastream_content?) { true }

    render
  end

  it 'has the audio player' do
    url = download_path(doc.id, datastream_id: 'ACCESS_MP3')

    expect(rendered).to have_selector("audio source[src='#{url}']")
  end

  it 'has download links for ARCHIVAL_WAV and ARCHIVAL_XML' do
    url = download_path(doc.id, datastream_id: 'ACCESS_MP3')

    expect(rendered).to have_selector("a[href='#{url}']", text: "Download ACCESS_MP3")
  end

end

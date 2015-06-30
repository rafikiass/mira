require 'spec_helper'

describe 'catalog/_show_datastream_download_link.html.erb' do
  let(:doc) { SolrDocument.new(id: 'tufts:1', displays_ssim: ['dl'], edited_at_dtsi: 'some date', published_at_dtsi: nil) }

  let(:dsid) { 'ARCHIVAL_WAV' }

  let(:download_section_title) { 'Download Section Title' }

  before do
    allow(view).to receive(:document) { doc }
    allow(view).to receive(:dsid) { dsid }
    allow(view).to receive(:download_section_title) { download_section_title }

    allow(doc).to receive(:transfer_binary_filename) { 'foo.zip' }
    allow(doc).to receive(:has_datastream_content?) { true }
  end

  context 'happy path' do
    before do
      render
    end

    it 'has the download section title and download link' do
      url = download_path(doc.id, datastream_id: dsid)

      expect(rendered).to have_selector('h3', text: download_section_title)
      expect(rendered).to have_selector("a[href='#{url}']", text: "Download ARCHIVAL_WAV")
    end

    context 'when the dsid is Transfer.binary' do
      let(:dsid) { "Transfer.binary" }

      it 'shows the documents transfer binary filename' do
        url = download_path(doc.id, datastream_id: dsid)

        expect(rendered).to have_selector("a[href='#{url}']", text: "Download foo.zip")
      end
    end
  end

  context 'when the document doesnt have datastream content for a dsid' do
    before do
      allow(doc).to receive(:has_datastream_content?) { false }
      render
    end

    it 'renders nothing' do
      expect(rendered).to be_blank
    end
  end
end

require 'spec_helper'

describe 'catalog/_show_tufts_video.html.erb' do
  let(:doc) { double('fake-solr-doc', id: 'tufts:123') }

  before do
    stub_template 'catalog/_show_default.html.erb' => '',
      'catalog/_show_datastream_download_link.html.erb' => ''

    allow(view).to receive(:document) { doc }

    render
  end

  context 'happy path' do
    it 'has video controls' do
      webm_path = download_path(doc.id, datastream_id: 'Access.webm')
      mp4_path = download_path(doc.id, datastream_id: 'Access.mp4')

      expect(rendered).to have_selector("video source[src='#{webm_path}']")
      expect(rendered).to have_selector("video source[src='#{mp4_path}']")
    end
  end

end

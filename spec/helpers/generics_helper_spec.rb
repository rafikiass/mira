require 'spec_helper'
describe GenericsHelper do
  let(:generic_object) { TuftsGenericObject.new(pid: 'tufts:99', displays: ['dl'], title: 'foo') }
  let(:solr_doc) { SolrDocument.new(generic_object.to_solr.merge("has_model_ssim"=>["info:fedora/cm:Object.Generic"])) }
  let(:xml) {
    '<content xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.fedora.info/definitions/">
  					        <item id="0">
    					         <link>http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS115/generic/MS115.003.001.00001.zip</link>
    					         <fileName>MS115.003.001.00001</fileName>
    					         <mimeType>application/zip</mimeType>
  					        </item>
				        </content>' }
  before { generic_object.datastreams['GENERIC-CONTENT'].content = xml; generic_object.save! }

  describe "generic_items" do
    subject { helper.generic_items(solr_doc) }
    it "has external links" do
      expect(subject.first[:download_path]).to eq '/downloads/tufts:99/0'
      expect(subject.first[:file_name]).to eq 'MS115.003.001.00001'

    end
  end
end

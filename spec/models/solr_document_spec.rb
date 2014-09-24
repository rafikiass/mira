require 'spec_helper'

describe SolrDocument do
  it "should have ancestors" do
    expect(SolrDocument.ancestors).to include(Blacklight::Solr::Document, Tufts::SolrDocument)
  end
end

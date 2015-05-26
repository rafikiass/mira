require 'spec_helper'

describe SolrDocument do
  it "should have ancestors" do
    expect(SolrDocument.ancestors).to include(Blacklight::Solr::Document, Tufts::SolrDocument)
  end

  describe "#published_at" do
    let(:doc) { SolrDocument.new("published_at_dtsi" => '2015-04-27') }
    subject { doc.published_at }
    it { is_expected.to eq '2015-04-27' }
  end

  describe "#draft?" do
    let(:doc) { SolrDocument.new("id" => pid) }
    subject { doc.draft? }
    context "when it's a draft" do
      let(:pid) { 'draft:123' }
      it { is_expected.to be true }
    end

    context "when it ain't" do
      let(:pid) { 'tufts:123' }
      it { is_expected.to be false }
    end
  end

  describe "#workflow_status" do
    let(:doc) { SolrDocument.new("id" => pid) }
    subject { doc.workflow_status }

    context "when it's a draft" do
      let(:pid) { 'draft:123' }
      context "and published" do
        before { allow(doc).to receive(:published?) { true } }
        it { is_expected.to eq :published }
      end

      context "and not published" do
        before { allow(doc).to receive(:published?) { false } }
        context "and published_at is set" do
          before { allow(doc).to receive(:published_at) { '2015' } }
          it { is_expected.to eq :edited }
        end
        context "and published_at is not set" do
          it { is_expected.to eq :unpublished } # you can reach this state from the unpublish method, so 'new' is misleading
        end
      end
    end

    context "when it is a production object" do
      let(:pid) { 'tufts:123' }
      it { is_expected.to eq :published } # all production objects must have been published / should have 'published' as their workflow state
    end
  end

end

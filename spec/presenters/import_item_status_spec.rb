require 'spec_helper'

describe ImportItemStatus do
  let(:item) { described_class.new(batch, pid) }

  describe "#status" do
    let(:batch) { double }
    let(:pid) { 'tufts:9999' }

    subject { item.status }

    before do
      allow(ActiveFedora::Base).to receive(:exists?).with('tufts:9999').and_return(exists)
    end

    context "when there is no record for the pid" do
      let(:exists) { false }
      it { is_expected.to eq 'Status not available' }
    end

    context "when there a record for the pid" do
      let(:exists) { true }
      it { is_expected.to eq 'Completed' }
    end
  end
end

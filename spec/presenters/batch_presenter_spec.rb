require 'spec_helper'

describe BatchPresenter do
  let(:presenter) { described_class.new(batch) }
  let(:batch) { double }

  describe "#items" do
    subject { presenter.items }
    let(:pids) { ['tufts:9999'] }
    before { allow(batch).to receive(:pids).and_return(pids) }

    it "returns a list of BatchItemStatus" do
      expect(subject).to be_kind_of Array
      expect(subject.size).to eq 1
      expect(subject).to all(be_kind_of BatchItemStatus)
    end
  end

  describe "#item_count" do
    before { allow(batch).to receive(:job_ids) { [1234] } }
    subject { presenter.item_count }
    it { is_expected.to eq 1 }
  end

  describe "#review_status" do
    subject { presenter.review_status }
    before { allow(presenter).to receive(:items).and_return(items) }
    context "with some items reviewed" do
      let(:items) { [double(reviewed?: false), double(reviewed?: true)] }
      it { is_expected.to eq 'Incomplete' }
    end

    context "with all items reviewed" do
      let(:items) { [double(reviewed?: true), double(reviewed?: true)] }
      it { is_expected.to eq 'Complete' }
    end
  end
end

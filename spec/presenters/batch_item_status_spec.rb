require 'spec_helper'

describe BatchItemStatus do
  let(:item) { described_class.new(batch, pid) }
  let(:batch) { double }
  let(:pid) { 'tufts:9999' }

  describe "#pid" do
    subject { item.pid }
    context "when there is no record for the pid" do
      it { is_expected.to eq 'tufts:9999' }
    end
  end

  describe "#reviewed?" do
    before { allow(item).to receive(:record).and_return(record) }
    subject { item.reviewed? }

    context "when the record is reviewed" do
      let(:record) { double(reviewed?: true) }
      it { is_expected.to be true }
    end

    context "when the record is not reviewed" do
      let(:record) { double(reviewed?: false) }
      it { is_expected.to be false }
    end
  end

  describe "#status" do
    let(:batch) { double("batch", created_at: 2.days.ago) }
    let(:job) { double(status: "queued") }

    before do
      allow(item).to receive(:job).and_return(job)
    end

    subject { item.status }

    it { is_expected.to eq 'Queued' }

    context "when the status isn't available" do
      let(:job) { nil }
      it { is_expected.to eq 'Status not available' }
    end
  end

  context "when the record does not exist" do
    before do
      allow(ActiveFedora::Base).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
    end

    describe "#reviewed?" do
      it "returns false" do
        expect(item).to_not be_reviewed
      end
    end

    describe "#record_title" do
      it "returns a blank string" do
        expect(item.record_title).to eq("")
      end
    end

  end
end


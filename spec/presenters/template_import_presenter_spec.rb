require 'spec_helper'

describe TemplateImportPresenter do
  let(:presenter) { described_class.new(batch) }
  let(:batch) { double(pids: ['tufts:1']) }

  describe "#item_count" do
    subject { presenter.item_count }
    it { is_expected.to eq 1 }
  end

  describe "#items" do
    subject { presenter.items }
    let(:pids) { ['tufts:9999'] }
    before { allow(batch).to receive(:pids).and_return(pids) }

    it "returns a list of ImportItemStatus" do
      expect(subject).to be_kind_of Array
      expect(subject.size).to eq 1
      expect(subject).to all(be_kind_of ImportItemStatus)
    end
  end
end

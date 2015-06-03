require 'spec_helper'

describe XmlImportPresenter do
  let(:presenter) { described_class.new(batch) }
  let(:batch) { double(pids: ['tufts:1']) }

  describe "#item_count" do
    subject { presenter.item_count }
    it { is_expected.to eq 1 }
  end
end

require 'spec_helper'

describe BatchExportPresenter do
  let(:presenter) { described_class.new(batch) }
  let(:batch) { double(pids: %w(tufts:1 tufts:2)) }

  describe '#item_count' do
    subject { presenter.item_count }
    it { is_expected.to eq 2 }
  end
end


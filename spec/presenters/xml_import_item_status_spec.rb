require 'spec_helper'

describe XmlImportItemStatus do
  let(:line) { described_class.new(Batch.new, 'tufts:123', 'ARCHIVAL_WAV', 'foo.wav') }

  describe "#reviewed?" do
    before do
      allow(line).to receive(:record).and_return(double(reviewed?: false))
    end
    subject { line.reviewed? }
    it { is_expected.to be false }
  end
end

require 'spec_helper'

describe BatchPresenter do
  let(:presenter) { described_class.new(batch) }
  let(:batch) { double(to_param: 123) }

  describe '#to_param' do
    it 'delegates to the batch' do
      expect(presenter.to_param).to eq batch.to_param
    end
  end

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

  describe 'presenter_for' do

    subject { described_class.presenter_for(batch) }

    context 'for BatchTemplateImports' do
      let(:batch) { BatchTemplateImport.new }

      it 'returns a TemplateImportPresenter' do
        expect(subject.class).to eq(TemplateImportPresenter)
      end
    end

    context 'for BatchXmlImports' do
      let(:batch) { BatchXmlImport.new }

      it 'returns a TemplateImportPresenter' do
        expect(subject.class).to eq(XmlImportPresenter)
      end
    end

    context 'for BatchExports' do
      let(:batch) { BatchExport.new }

      it 'returns a BatchExportPresenter' do
        expect(subject.class).to eq(BatchExportPresenter)
      end
    end

    context 'for other batches' do
      it 'returns a BatchPresenter' do
        expect(subject.class).to eq(BatchPresenter)
      end
    end
  end
end

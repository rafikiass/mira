require 'spec_helper'

describe DraftExportService do
  let(:record_ids) { %w(tufts:123 draft:456) }
  let(:datastream_ids) { %w(DCA-META DC-DETAIL-META DCA-ADMIN RELS-EXT) }
  let(:export_directory) { nil }
  let(:options) {
    {
      record_ids: record_ids,
      datastream_ids: datastream_ids,
      batch_id: 1234,
      export_directory: export_directory
    }
  }

  let(:svc) {
    DraftExportService.new(options)
  }

  describe '#initialize' do
    it 'requires :record_ids' do
      expect { DraftExportService.new(options.except(:record_ids)) }.to raise_error(KeyError)
    end

    it 'requires :datastream_ids' do
      expect { DraftExportService.new(options.except(:datastream_ids)) }.to raise_error(KeyError)
    end

    it 'requires :batch_id' do
      expect { DraftExportService.new(options.except(:batch_id)) }.to raise_error(KeyError)
    end

    it 'converts all pids to draft' do
      svc = DraftExportService.new(options)
      expect(svc.record_ids).to eq(%w(draft:123 draft:456))
    end
  end

  describe '#export_directory' do
    subject { svc.export_directory }

    context 'when no export_directory supplied' do
      it 'uses Settings.object_store_root' do
        expect(subject).to eq(File.join(Settings.object_store_root, "export"))
      end
    end

  end

  describe '#run' do

    let(:fake_datastreams) {
      {
        "DCA-META" => double('fake-datastream-1', read: "<foo />"),
        "DC-DETAIL-META" => double('fake-datastream-2', read: "<bar />")
      }
    }

    let(:pdf) {
      TuftsPdf.new(title: 'text export pdf', displays: ['dl'], pid: 'tufts:123')
    }

    let(:img) {
      TuftsImage.new(title: 'text export image', displays: ['dl'], pid: 'tufts:456')
    }

    let(:record_ids) { [pdf.pid, img.pid] }

    let(:doc) { Nokogiri::XML(File.read(svc.full_export_file_path)) }

    before do
      expect(pdf).to receive(:save!)
      expect(img).to receive(:save!)
      allow(ActiveFedora::Base).to receive(:exists?).with('draft:123') { true }
      allow(ActiveFedora::Base).to receive(:exists?).with('draft:456') { true }
      allow(ActiveFedora::Base).to receive(:exists?).with('draft:999') { false }

      expect(ActiveFedora::Base).to receive(:find).with(['draft:123', 'draft:456']) { [pdf, img] }

      svc.run
    end

    after do
      FileUtils.rm(svc.full_export_file_path)
    end

    it 'generates a file in the expected location' do
      expect(File).to exist(svc.full_export_file_path)
    end

    it 'adds batchID to the objects' do
      expect(pdf.batch_id).to eq ['1234']
    end

    describe '#full_export_file_path' do
      subject { svc.full_export_file_path }

      it 'is named including the supplied batch_id' do
        expect(subject).to eq(File.join(Settings.object_store_root, "export", "batch_1234.xml"))
      end

    end


    context 'the generated xml document' do
      subject { doc }

      it 'is in the correct format' do
        expect(subject.xpath('/items/digitalObject').count).to eq(2)
        expect(subject.xpath('/items/digitalObject[1]/pid').text).to eq(pdf.pid)
        expect(subject.xpath('/items/digitalObject[1]/datastream').count).to eq(4)

        expect(subject.xpath('/items/digitalObject[2]/pid').text).to eq(img.pid)
        expect(subject.xpath('/items/digitalObject[2]/datastream').count).to eq(4)
      end
    end

    it "includes empty dataStream objects in the output" do
      allow(pdf).to receive(:datastreams) { { "DC-DETAIL-META" => double('fake-datastream', read: "") } }

      dca_meta_node = doc.xpath("/items/digitalObject[1]/datastream[@id=DC-DETAIL-META]")

      expect(dca_meta_node.children.size).to eq(0)
    end

    context "when not all of the draft pids exist" do
      let(:record_ids) { [pdf.pid, img.pid, 'fake:999'] }
      subject { doc }

      it "handles missing pids gracefully" do
        expect(subject.xpath('/items/digitalObject').size).to eq(2)
      end
    end

  end
end

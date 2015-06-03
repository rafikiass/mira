require 'spec_helper'

describe XmlBatchImportAction do
  let(:batch) { double('XmlBatchImport', id: 123, metadata_file: xml_file, uploaded_files: uploaded_files) }
  let(:xml_file) { StringIO.new(xml) }
  let(:current_user) { double(user_key: 'jcoyne@curationexperts') }
  let(:action) { described_class.new(batch, current_user, documents) }

  describe "#run" do
    context "with multiple files per record" do
      let(:pdf) { double(original_filename: 'AK-Page4.pdf', content_type: 'application/pdf', read: 'bytes') }
      let(:docx) { double(original_filename: 'Anna Karenina.docx', content_type: 'application/docx', read: 'bytes') }
      let(:uploaded_files) { [] }
      let(:documents) { [pdf, docx] }

      let(:draft_pid) { 'draft:1' }
      let(:published_pid)   { 'tufts:1' }

      let(:xml) { '<input>
       <digitalObject xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:admin="http://nils.lib.tufts.edu/dcaadmin/"
            xmlns:rel="info:fedora/fedora-system:def/relations-external#">
          <pid>tufts:1</pid>
          <file datastream="Archival.pdf">AK-Page4.pdf</file>
          <file datastream="Transfer.binary">Anna Karenina.docx</file>
          <rel:hasModel>info:fedora/cm:Text.PDF</rel:hasModel>
          <dc:title>Anatomical tables of the human body.</dc:title>
          <admin:displays>dl</admin:displays>
                  </digitalObject></input>'}

      before { TuftsPdf.destroy_all }

      it "attaches one file per datastream" do
        expect(uploaded_files).to receive(:build).twice
        expect(batch).to receive(:save)
        expect { action.run }.to change { TuftsPdf.count }.by(1)
        new_datastreams = TuftsPdf.first.datastreams
        expect(new_datastreams['Archival.pdf']).not_to be_new
        expect(new_datastreams['Transfer.binary']).not_to be_new
      end

      context "with an existing published record" do
        let!(:draft_record) {
          draft = TuftsPdf.build_draft_version(displays: ['dl'], title: "orig title", pid: draft_pid)
          draft.save!
          draft
        }

        let!(:published_record) {
          PublishService.new(draft_record).run
          TuftsPdf.find(published_pid)
        }

        let(:xmas) { DateTime.parse('2014-12-25 11:30') }

        before do
          allow(uploaded_files).to receive(:build)
          allow(batch).to receive(:save)

          # Because the workflow_status depends on comparing
          # timestamps, hard-code the timestamps to a known
          # time, otherwise this test might intermittently fail
          # if it takes less than 1 second to run.
          # Using the reverting flag is a trick to allow me to
          # set edited_at directly, so that the save won't
          # overwrite it with DateTime.now.
          [draft_record, published_record].each do |record|
            record.reverting = true
            record.edited_at = xmas
            record.published_at = xmas
            record.save!
            record.reverting = false
          end
        end

        it "has the correct workflow status after import" do
          expect(draft_record.workflow_status).to eq :published
          expect { action.run }.to change { TuftsPdf.count }.by(0)
          expect(draft_record.reload.workflow_status).to eq :edited
          expect(draft_record.published_at).to eq xmas
          expect(draft_record.edited_at).to_not eq xmas
        end
      end
    end

  end

  describe "#collect_warning" do
    let(:batch) { double('XmlBatchImport') }
    let(:documents) { [] }

    let(:doc) { double(content_type: content_type, original_filename: 'MSS025.006.004.archival.wav') }

    subject { action.collect_warning(TuftsAudio.new, 'ARCHIVAL_WAV', doc) }

    context "with a valid mime-type" do
      let(:content_type) { 'audio/x-wav' }
      it { is_expected.to be_nil }
    end

    context "with an invalid mime-type" do
      let(:content_type) { 'application/pdf' }
      it { is_expected.to eq 'You provided a application/pdf file, which is not a valid type for: ARCHIVAL_WAV' }
    end
  end
end

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
    end
  end
end

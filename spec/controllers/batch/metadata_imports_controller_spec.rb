require 'spec_helper'

describe Batch::MetadataImportsController do
  context "non admin" do
    it 'denies access to new' do
      get :new
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "signed in as an admin" do
    let(:user) { create(:admin) }

    before do
      sign_in user
    end
    describe "new" do
      it "is successful" do
        get :new
        expect(response).to be_successful
        expect(assigns[:metadata_import]).to be_kind_of Batch::MetadataImport
      end
    end

    describe "create" do
      let(:service) { double }
      let(:parser) { double('Parser', valid?: true, pids: ["draft:12440", "draft:12439"]) }

      let(:file) { fixture_file_upload('export/sample_export.xml', 'application/xml') }
      let(:xml) { file.read.tap { file.rewind } }

      before do
        allow(MetadataImportParser).to receive(:new).with(xml).and_return(parser)
        allow(BatchRunnerService).to receive(:new).with(an_instance_of(Batch::MetadataImport)) { service }
      end

      context "with a good import file" do
        it "makes an import" do
          expect(service).to receive(:run) { true }
          get :create, batch_metadata_import: { metadata_file: file }
          expect(response).to redirect_to assigns[:metadata_import]
          expect(assigns[:metadata_import].pids).to eq ["draft:12440", "draft:12439"]
        end

        pending "works with files longer than 64K"
        # is there a way to dynamically pad export/sample_export.xml with 64K spaces?
      end

      context "with a bad import file" do
        before do
          allow(parser).to receive(:valid?).and_return(false)
          allow(parser).to receive(:errors).and_return(["The file you uploaded doesn't contain any digital objects"])
        end
        it "doesn't import" do
          expect(service).not_to receive(:run)
          get :create, batch_metadata_import: { metadata_file: file }
          expect(response).to render_template :new
          expect(flash[:error]).to eq "The file you uploaded doesn't contain any digital objects"
        end
      end
    end

    describe "show" do
      let(:metadata_import) { Batch::MetadataImport.create!(creator: user) }
      it "shows the batch" do
        get :show, id: metadata_import
      end
    end
  end
end

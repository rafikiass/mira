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
      let(:file) { fixture_file_upload('export/sample_export.xml', 'application/xml') }

      it "makes an import" do
        expect(BatchRunnerService).to receive(:new).with(an_instance_of(Batch::MetadataImport)) { service }
        expect(service).to receive(:run) { true }
        get :create, batch_metadata_import: { metadata_file: file }
        expect(response).to redirect_to assigns[:metadata_import]
        expect(assigns[:metadata_import].pids).to eq ["draft:12440", "draft:12439", "draft:12438", "draft:12437", "draft:12436", "draft:12435", "draft:12432", "draft:12430", "draft:12429", "draft:12428"]
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

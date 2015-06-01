require 'spec_helper'

describe Batch::XmlImportsController do
  let(:batch_xml_import) { create(:batch_xml_import ) }

  context "non admin" do
    it 'denies access to create' do
      post :create
      response.should redirect_to(new_user_session_path)
    end
    it 'denies access to show' do
      get :show, id: batch_xml_import
      response.should redirect_to(new_user_session_path)
    end
  end

  context "an admin" do
    before do
      sign_in FactoryGirl.create(:admin)
    end

    describe "GET 'new'" do
      before { get :new }

      it "returns http success" do
        expect(response).to be_success
        expect(response).to render_template(:new)
        expect(assigns[:batch]).to be_kind_of BatchXmlImport
      end
    end


    describe "POST 'create'" do
      it 'creates a batch' do
        different_user = create(:admin)
        attrs = attributes_for(:batch_xml_import, creator_id: different_user.id)
        expect {
          post 'create', batch_xml_import: attrs
        }.to change { BatchXmlImport.count }.by(1)
        expect(assigns[:batch]).to be_kind_of BatchXmlImport
        expect(response).to redirect_to(edit_batch_xml_import_path(assigns[:batch]))
        expect(assigns[:batch].creator).to eq controller.current_user
      end

      describe 'error path' do
        it 'renders :new form' do
          post 'create', batch_xml_import: { metadata_file: 'invalid' }
          expect(response).to render_template :new
        end
      end
    end

    describe "GET 'edit'" do
      let(:batch) { create(:batch_xml_import) }

      before do
        ActiveFedora::Base.delete_all
        TuftsPdf.create(attributes_for(:tufts_pdf, pid: 'tufts:1'))
      end

      it 'assigns @pids_that_already_exist' do
        get :edit, id: batch
        expect(assigns[:pids_that_already_exist]).to eq ['tufts:1']
      end
    end

    describe "PATCH 'update'" do
      let(:uploaded_files) { [UploadedFile.new(filename: "file.jpg", pid: "oldpid:123")] }
      let(:batch) { create(:batch_xml_import, uploaded_files: uploaded_files) }
      let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'hello.pdf'), "application/pdf") }
      let(:file2) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'hello2.pdf'), "application/pdf") }

      describe 'happy path' do
        before do
          TuftsPdf.delete_all
          patch :update, id: batch.id, documents: [file1, file2], batch: {}
        end

        it_behaves_like 'an import happy path'

        it "remembers what uploaded files map to what pids" do
          expected_filenames = ['file.jpg', 'hello.pdf', 'hello2.pdf']
          expect(assigns[:batch].reload.uploaded_files.map(&:filename)).to match_array expected_filenames
          specified_pid = "draft:1"
          generated_pid = (TuftsPdf.all.map(&:pid) - [specified_pid]).first
          expect(generated_pid).to match /^#{PidUtils.draft_namespace}:.*$/
          expect(assigns[:batch].uploaded_files.find { |f| f.filename == file1.original_filename }.pid).to eq "draft:1"
          expect(assigns[:batch].uploaded_files.find { |f| f.filename == file2.original_filename }.pid).to eq generated_pid
        end

      end

      it_behaves_like 'an import error path (no documents uploaded)'
      it_behaves_like 'an import error path (wrong file format)'

      context "uploading two of the same file" do
        let(:file3) { file1 }
        before do
          TuftsPdf.delete_all
        end

        it "displays a warning" do
          expect {
            patch :update, id: batch.id, documents: [file1, file2, file3], batch: {}
          }.to change { TuftsPdf.count }.by(2)
          expect(flash[:alert]).to match "#{file3.original_filename} has already been uploaded"
          expect(TuftsPdf.count).to eq 2
        end
      end

      context "adding a file that was uploaded previously" do
        let!(:record) do
          create(:tufts_pdf).tap do |r|
            ArchivalStorageService.new(r, TuftsPdf.default_datastream, file1).run
            r.save!
          end
        end

        let(:uploaded_files) { [UploadedFile.new(filename: "hello.pdf", pid: record.pid)] }
        let(:batch) do
          create(:batch_xml_import, uploaded_files: uploaded_files)
        end

        it "displays a warning" do
          expect {
            patch :update, id: batch.id, documents: [file1], batch: {}
          }.not_to change { TuftsPdf.count }
          expect(flash[:alert]).to match "#{file1.original_filename} has already been uploaded"
        end
      end

      context "with a file that isn't in the metadata" do
        let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'tufts_RCR00728.foxml.xml')) }

        it "displays a warning" do
          expect {
            patch :update, id: batch.id, documents: [file1], batch: {}
          }.not_to change { TuftsPdf.count }
          expect(flash[:alert]).to match "#{file1.original_filename} doesn't exist in the metadata file"
        end
      end

      describe 'JSON request' do
        it_behaves_like 'a JSON import'

        context "with duplicate file upload" do
          let!(:record) do
            create(:tufts_pdf).tap do |r|
              ArchivalStorageService.new(r, TuftsPdf.default_datastream, file1).run
            end
          end

          let(:uploaded_files) { [UploadedFile.new(filename: "hello.pdf", pid: record.pid)] }
          let(:batch) do
            create(:batch_xml_import, uploaded_files: uploaded_files)
          end

          it "displays a warning" do
            patch :update, id: batch.id, documents: [file1], batch: {}, format: :json
            json = JSON.parse(response.body)['files'].first
            expect(json['error']).to eq ["#{file1.original_filename} has already been uploaded"]
          end
        end

        context "with a file that isn't in the metadata" do
        let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'tufts_RCR00728.foxml.xml')) }

          it "displays a warning" do
            patch :update, id: batch.id, documents: [file1], batch: {}, format: :json
            json = JSON.parse(response.body)['files'].first
            expect(json['error']).to eq ["#{file1.original_filename} doesn't exist in the metadata file"]
            expect(json['name']).to eq file1.original_filename
          end
        end

        describe 'error path (failed to save batch)' do
          before do
            allow_any_instance_of(ActiveRecord::Relation).to receive(:find) { batch }
            allow(batch).to receive(:save) { false }
            batch.errors.add(:base, 'Batch Error 1')
            patch :update, id: batch.id, documents: [file1], format: :json
          end

          it 'returns JSON data needed by the view template' do
            json = JSON.parse(response.body)['files'].first
            expect(json['pid']).to match /^draft:\d+$/
            doc = Nokogiri::XML(batch.metadata_file.read)
            title = doc.at_xpath("//digitalObject[child::file/text()='#{file1.original_filename}']/*[local-name()='title']").content
            expect(json['title']).to eq title
            expect(json['name']).to eq file1.original_filename
            expect(json['error']).to eq ['Batch Error 1']
          end
        end
      end  # JSON request
    end

    describe "GET 'show'" do
      let(:batch_xml_import) { FactoryGirl.create(:batch_xml_import, uploaded_files: uploaded_files) }

      context 'happy path' do
        let(:uploaded_files) { [UploadedFile.new(filename: "one", pid: 'tufts:my-pid')] }
        let(:records) { [double(pid: 'tufts:my-pid')] }
        before do
          allow(ActiveFedora::Base).to receive(:find).with('tufts:my-pid', { cast: true }).and_return(records.first)
        end

        it "returns http success" do
          get :show, id: batch_xml_import.id
          expect(response).to be_success
          expect(response).to render_template(:show)
          expect(assigns[:batch].id).to eq batch_xml_import.id
          expected = records.reduce({}) { |acc, r| acc.merge(r.pid => r) }
          expect(assigns[:records_by_pid]).to eq expected
        end
      end

      context 'with no pids (yet)' do
        let(:uploaded_files) { [] }
        it 'gracefully sets @records_by_pid empty' do
          get :show, id: batch_xml_import
          expect(assigns[:records_by_pid]).to eq({})
        end
      end

      context 'with pids that have been deleted' do
        let(:uploaded_files) { [UploadedFile.new(filename: "one", pid: 'tufts:never-existed')] }
        it 'returns http success' do
          get :show, id: batch_xml_import
          expect(response).to be_success
        end
      end
    end
  end
end

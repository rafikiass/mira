require 'spec_helper'

describe Batches::XmlImportController do
  let(:batch_xml_import) { FactoryGirl.create(:batch_xml_import ) }

  context "non admin" do
    it 'denies access to create' do
      post :create
      response.should redirect_to(new_user_session_path)
    end
    it 'denies access to show' do
      get :show, id: batch_xml_import
      response.should redirect_to(new_user_session_path)
    end
    it 'denies access to new_template_import' do
      get :new
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
        different_user = FactoryGirl.create(:admin)
        attrs = FactoryGirl.attributes_for(:batch_xml_import, creator_id: different_user.id)
        expect {
          post 'create', batch_xml_import: attrs
        }.to change { BatchXmlImport.count }.by(1)
        expect(assigns[:batch]).to be_kind_of BatchXmlImport
        expect(response).to redirect_to(edit_batches_xml_import_path(assigns[:batch]))
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
      let(:batch) { FactoryGirl.create(:batch_xml_import) }

      before do
        ActiveFedora::Base.delete_all
        TuftsPdf.create(FactoryGirl.attributes_for(:tufts_pdf, pid: 'tufts:1'))
      end

      it 'assigns @pids_that_already_exist' do
        get :edit, id: batch
        expect(assigns[:pids_that_already_exist]).to eq ['tufts:1']
      end
    end

    describe "PATCH 'update'" do
      let(:batch) { FactoryGirl.create(:batch_xml_import, uploaded_files: {'file.jpg' => 'oldpid:123'}) }
      let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'hello.pdf'), "application/pdf") }
      let(:file2) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'hello2.pdf'), "application/pdf") }

      describe 'happy path' do
        before do
          TuftsPdf.delete_all
          patch :update, id: batch.id, documents: [file1, file2], batch: {}
        end

        it_behaves_like 'an import happy path'

        it "remembers what uploaded files map to what pids" do
          expected_filenames = ['file.jpg'] + [file1, file2].map(&:original_filename)
          expect(assigns[:batch].reload.uploaded_files.keys.sort).to eq expected_filenames.sort
          specified_pid = "draft:1"
          generated_pid = (TuftsPdf.all.map(&:pid) - [specified_pid]).first
          expect(generated_pid).to match /^#{PidUtils.draft_namespace}:.*$/
          expect(assigns[:batch].uploaded_files[file1.original_filename]).to eq "draft:1"
          expect(assigns[:batch].uploaded_files[file2.original_filename]).to eq generated_pid
        end

      end

      it_behaves_like 'an import error path (no documents uploaded)'
      it_behaves_like 'an import error path (wrong file format)'
      it_behaves_like 'an import error path (failed to save batch)'

      context "uploading two of the same file" do
        let(:file3) { file1 }
        before do
          TuftsPdf.delete_all
          patch :update, id: batch.id, documents: [file1, file2, file3], batch: {}
        end

        it "displays a warning" do
          expect(flash[:alert]).to match "#{file3.original_filename} has already been uploaded"
        end

        it "doesn't save the duplicate file" do
          expect(TuftsPdf.count).to eq 2
        end
      end

      context "adding a file that was uploaded previously" do
        let(:record) do
          FactoryGirl.create(:tufts_pdf).tap do |r|
            ArchivalStorageService.new(r, TuftsPdf.original_file_datastreams.first, file1).run
            r.save!
          end
        end

        let(:batch) do
          FactoryGirl.create(:batch_xml_import, uploaded_files: {'hello.pdf' => record.pid})
        end

        before do
          TuftsPdf.delete_all
          record # force creation of existing record
          @pdf_count = TuftsPdf.count
          patch :update, id: batch.id, documents: [file1], batch: {}
        end

        it "displays a warning" do
          expect(flash[:alert]).to match "#{file1.original_filename} has already been uploaded"
        end

        it "doesn't save the duplicate file" do
          expect(TuftsPdf.count).to eq @pdf_count
        end
      end

      context "with a file that isn't in the metadata" do
        let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'tufts_RCR00728.foxml.xml')) }
        before do
          TuftsPdf.delete_all
          patch :update, id: batch.id, documents: [file1], batch: {}
        end

        it "displays a warning" do
          expect(flash[:alert]).to match "#{file1.original_filename} doesn't exist in the metadata file"
        end

        it "doesn't save the file" do
          expect(TuftsPdf.count).to eq 0
        end
      end

      describe 'JSON request' do
        before { TuftsPdf.delete_all }
        after { TuftsPdf.delete_all }

        it_behaves_like 'a JSON import'

        context "with duplicate file upload" do
          let(:record) do
            FactoryGirl.create(:tufts_pdf).tap do |r|
              ArchivalStorageService.new(r, TuftsPdf.original_file_datastreams.first, file1).run
            end
          end

          let(:batch) do
            FactoryGirl.create(:batch_xml_import, uploaded_files: {'hello.pdf' => record.pid})
          end

          before do
            TuftsPdf.delete_all
            record # force creation of existing record
            patch :update, id: batch.id, documents: [file1], batch: {}, format: :json
          end

          it "displays a warning" do
            json = JSON.parse(response.body)['files'].first
            expect(json['error']).to eq ["#{file1.original_filename} has already been uploaded"]
          end
        end

        context "with a file that isn't in the metadata" do
        let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'tufts_RCR00728.foxml.xml')) }
          before do
            TuftsPdf.delete_all
            patch :update, id: batch.id, documents: [file1], batch: {}, format: :json
          end

          it "displays a warning" do
            json = JSON.parse(response.body)['files'].first
            expect(json['error']).to eq ["#{file1.original_filename} doesn't exist in the metadata file"]
          end

          it "displays the filename" do
            json = JSON.parse(response.body)['files'].first
            expect(json['name']).to eq file1.original_filename
          end
        end

        describe 'error path (failed to save batch)' do
          before do
            allow_any_instance_of(ActiveRecord::Relation).to receive(:find) { batch }
            allow(batch).to receive(:save) { false }
            @batch_error = 'Batch Error 1'
            batch.errors.add(:base, @batch_error)
            patch :update, id: batch.id, documents: [file1], format: :json
          end

          it 'returns JSON data needed by the view template' do
            json = JSON.parse(response.body)['files'].first
            expect(json['pid']).to eq TuftsPdf.first.pid
            doc = Nokogiri::XML(batch.metadata_file.read)
            title = doc.at_xpath("//digitalObject[child::file/text()='#{file1.original_filename}']/*[local-name()='title']").content
            expect(json['title']).to eq title
            expect(json['name']).to eq file1.original_filename
            expect(json['error']).to eq [@batch_error]
          end
        end
      end  # JSON request
    end

    describe "GET 'show'" do
      context 'happy path' do
        let(:batch_xml_import) { FactoryGirl.create(:batch_xml_import, uploaded_files: {'one' => 'tufts:my-pid'} ) }
        let(:records) { [double(pid: 'tufts:my-pid')] }
        before do
          allow(ActiveFedora::Base).to receive(:find).with('tufts:my-pid', {:cast=>true}).and_return(records.first)
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
        let(:batch_xml_import) { FactoryGirl.create(:batch_xml_import, uploaded_files: nil ) }
        it 'gracefully sets @records_by_pid empty' do
          get :show, id: batch_xml_import
          expect(assigns[:records_by_pid]).to eq({})
        end
      end

      context 'with pids that have been deleted' do
        let(:batch_xml_import) { FactoryGirl.create(:batch_xml_import, uploaded_files: {'one' => 'tufts:never-existed'} ) }
        it 'returns http success' do
          get :show, id: batch_xml_import
          expect(response).to be_success
        end
      end
    end
  end
end

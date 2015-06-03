require 'spec_helper'

describe Batch::TemplateImportsController do
  let(:batch_template_import) { create(:batch_template_import,
                                                   pids: records.map(&:id)) }
  let(:records) { [create(:tufts_pdf)] }

  context "non admin" do
    it 'denies access to create' do
      post :create
      expect(response).to redirect_to(new_user_session_path)
    end
    it 'denies access to show' do
      get :show, id: batch_template_import
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "an admin" do
    let(:user) { create(:admin) }
    before do
      sign_in user
    end

    describe "GET 'new'" do
      it "returns http success" do
        get :new
        expect(response).to be_success
        expect(response).to render_template :new
        expect(assigns[:batch].class).to eq BatchTemplateImport
      end
    end

    describe "POST 'create'" do

      describe 'happy path' do
        it 'assigns the current user as the creator' do
          different_user = create(:admin)
          attrs = attributes_for(:batch_template_import, creator_id: different_user.id)
          expect {
          post 'create', batch: attrs
          }.to change { Batch.count }.by(1)
          expect(assigns[:batch].class).to eq BatchTemplateImport
          expect(assigns[:batch].creator).to eq controller.current_user
          expect(response).to redirect_to([:edit, assigns[:batch]])
        end
      end

      describe 'error path' do
        it 'renders :new form' do
          post 'create', batch: { type: 'BatchTemplateImport'}
          expect(response).to render_template :new
        end
      end
    end


    describe "GET 'edit'" do
      context "template import" do
        let(:batch_template_import) { create(:batch_template_import) }

        it "returns http success" do
          get :edit, id: batch_template_import
          response.should be_success
          expect(assigns[:batch]).to eq batch_template_import
          response.should render_template(:edit)
        end
      end
    end


    describe "PATCH 'update'" do
      let(:batch) { create(:batch_template_import, pids: ['oldpid:123']) }
      let(:file1) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'hello.pdf'), 'application/pdf') }
      let(:file2) { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'hello.pdf')) }

      describe 'happy path' do
        before do
          TuftsPdf.delete_all
          patch :update, id: batch.id, documents: [file1, file2], batch: {}
        end

        it_behaves_like 'an import happy path'

        it 'creates the records with the template attributes' do
          expect(TuftsPdf.count).to eq 2
          expect(TuftsPdf.first.title).to eq batch.template.title
        end

        it 'creates a draft object' do
          expect(TuftsPdf.first.pid).to match /^#{PidUtils.draft_namespace}:.*$/
        end
      end

      it_behaves_like 'an import error path (no documents uploaded)'
      it_behaves_like 'an import error path (wrong file format)'

      describe 'an import error path (failed to save batch)' do
        before do
          allow_any_instance_of(ActiveRecord::Relation).to receive(:find) { batch }
          allow(batch).to receive(:save) { false }
          @batch_error = 'Batch Error 1'
          batch.errors.add(:base, @batch_error)
          patch :update, id: batch.id, documents: [file1]
        end

        it 'returns to the edit page' do
          expect(response).to render_template(:edit)
        end
      end

      describe 'JSON request' do
        before { TuftsPdf.delete_all }
        after { TuftsPdf.delete_all }

        it_behaves_like 'a JSON import'

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
            expect(json['title']).to eq batch.template.title
            expect(json['name']).to eq file1.original_filename
            expect(json['error']).to eq [@batch_error]
          end
        end
      end  # JSON request
    end

    describe "GET 'show'" do
      describe 'happy path' do
        it "returns http success" do
          get :show, id: batch_template_import
          response.should be_success
          response.should render_template(:show)
          expect(assigns[:batch]).to be_kind_of BatchPresenter
          expect(assigns[:batch].id).to eq batch_template_import.id
        end
      end

      context 'with no pids (yet)' do
        let(:batch_template_import) { create(:batch_template_import, pids: nil) }

        it 'has no items in the presenter' do
          get :show, id: batch_template_import
          expect(assigns[:batch]).to be_kind_of BatchPresenter
          expect(assigns[:batch].item_count).to eq 0
        end
      end

      context 'with pids that have been deleted' do
        let(:batch_template_import) { create(:batch_template_import, pids: ['tufts:999']) }

        it 'returns http success' do
          get :show, id: batch_template_import
          expect(response).to be_success
        end
      end
    end
  end
end

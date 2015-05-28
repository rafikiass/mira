require 'spec_helper'

describe Batch::TemplateUpdatesController do
  let(:batch_template_update) { create(:batch_template_update, pids: records.map(&:id)) }
  let(:records) { [create(:tufts_pdf)] }

  context "non admin" do
    it 'denies access to create' do
      post :create
      response.should redirect_to(new_user_session_path)
    end

    it 'denies access to show' do
      get :show, id: batch_template_update.id
      response.should redirect_to(new_user_session_path)
    end
  end

  describe "an admin" do
    let(:user) { create(:admin) }
    before do
      sign_in user
    end

    describe "GET 'new'" do
      context "with pids provided" do
        it 'renders the form to select the template' do
          get 'new', pids: ['pid:1']
          expect(flash).to be_empty
          expect(assigns(:batch).errors).to be_empty
          expect(assigns(:batch).pids).to eq ['draft:1']
          expect(response).to render_template(:new)
        end
      end

      context "without pids" do
        before do
          allow(controller.request).to receive(:referer) { catalog_index_path }
        end

        it 'renders the form to select the template' do
          get 'new', pids: []
          expect(flash[:error]).to eq "Please select some records to do batch updates."
          expect(response).to redirect_to(request.referer)
        end
      end

    end

    describe "POST 'create'" do
      let(:different_user) { create(:admin) }
      it 'creates a batch' do
        expect_any_instance_of(BatchTemplateUpdateRunnerService).to receive(:run) { true }
        expect {
          post 'create', batch_template_update: attributes_for(:batch_template_update, creator_id: different_user.id)
        }.to change { Batch.count }.by(1)
        expect(assigns[:batch]).to be_kind_of BatchTemplateUpdate
        expect(assigns[:batch].creator).to eq controller.current_user
        expect(response).to redirect_to(assigns[:batch])
      end

      context 'error path - no pids were selected:' do
        context "when referrer is set" do
          before do
            allow(controller.request).to receive(:referer) { catalog_index_path }
          end
          it 'redirects to previous page' do
            post :create, batch_template_update: attributes_for(:batch_template_update, pids: [])
            expect(response).to redirect_to(request.referer)
          end
        end

        it 'redirects to root if there is no referer' do
          post :create, batch_template_update: attributes_for(:batch_template_update, pids: [])
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to eq 'Please select some records to do batch updates.'
        end
      end

      context 'error path - batch fails to run:' do
        before do
          allow_any_instance_of(BatchTemplateUpdateRunnerService).to receive(:run) { false }
        end

        it "doesn't create a batch object" do
          attrs = attributes_for(:batch_template_update)
          expect {
            post :create, batch_template_update: attrs
          }.not_to change { Batch.count }
          expect(flash[:error]).to eq 'Unable to run batch, please try again later.'
          expect(assigns[:batch].pids).to eq attrs[:pids]
          expect(assigns[:batch]).to be_new_record
        end
      end

      it "renders new when there are form errors" do
        allow_any_instance_of(BatchTemplateUpdateRunnerService).to receive(:run) { true }
        post 'create', batch_template_update: attributes_for(:batch_template_update).merge(template_id: nil)
        expect(flash).to be_empty
        assigns(:batch).errors[:template_id].include?("can't be blank").should be_truthy
        expect(response).to render_template(:new)
      end

      it 'renders new when batch fails to run' do
        BatchTemplateUpdate.any_instance.stub(:save) { true }
        allow_any_instance_of(BatchTemplateUpdateRunnerService).to receive(:run) { false }
        post 'create', batch_template_update: {type: "BatchTemplateUpdate", pids: ['pid:1']}
        response.should render_template(:new)
      end
    end

    describe "GET 'show'" do
      describe 'happy path' do
        it "returns http success" do
          get :show, id: batch_template_update
          expect(response).to be_success
          expect(response).to render_template(:show)
          expect(assigns[:batch].id).to eq batch_template_update.id
          expected = records.reduce({}) { |acc, r| acc.merge(r.pid => r) }
          expect(assigns[:records_by_pid]).to eq expected
        end
      end

      context 'with pids that have been deleted' do
        let(:batch) { create(:batch_template_update, pids: ['draft:999']) }

        it 'returns http success' do
          get :show, id: batch
          expect(response).to be_success
        end
      end
    end
  end
end

require 'spec_helper'

describe Batch::UnpublishesController do
  let(:batch_unpublish) { create(:batch_unpublish) }

  context "non admin" do
    it 'denies access to create' do
      post :create
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'denies access to show' do
      get :show, id: batch_unpublish
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "an admin" do
    let(:user) { create(:admin) }
    before do
      sign_in user
    end


    describe "POST 'create'" do
      context "happy path" do
        let(:different_user) { create(:admin) }

        it 'creates a batch' do
          expect_any_instance_of(BatchRunnerService).to receive(:run) { true }
          expect {
            post 'create', pids: ['tufts:1', 'tufts:2']
          }.to change { Batch.count }.by(1)
          expect(assigns[:batch]).to be_kind_of BatchUnpublish
          expect(assigns[:batch].creator).to eq controller.current_user
          expect(response).to redirect_to(assigns[:batch])
        end
      end

      context "with duplicate pids" do
        let(:pids) { %w(tufts:1 tufts:2 tufts:1) }

        it "creates a batch with just the unique pids" do
          expect(BatchUnpublish).to receive(:new).with(pids: pids.uniq) { mock_model(BatchUnpublish) }

          post "create", pids: pids
        end

      end

      context 'error path - no pids were selected:' do

        context "with a referrer" do
          before { allow(controller.request).to receive(:referer) { catalog_index_path } }

          it 'redirects to previous page' do
            allow(controller.request).to receive(:referer) { catalog_index_path }
            post :create, pids: []
            expect(response).to redirect_to(request.referer)
            expect(flash[:error]).to eq 'Please select some records to do batch updates.'
          end
        end

        context "with no referrer" do
          it 'redirects to root' do
            post :create, pids: []
            expect(response).to redirect_to(root_path)
            expect(flash[:error]).to eq 'Please select some records to do batch updates.'
          end
        end
      end

      context "error path - service fault" do
        before { allow(controller.request).to receive(:referer) { catalog_index_path } }

        it "redirects to previous page" do
          allow_any_instance_of(BatchUnpublish).to receive(:save) { true }
          allow_any_instance_of(BatchRunnerService).to receive(:run) { false }
          expect {
            post :create, pids: ['pid:1']
          }.not_to change { Batch.count }
          expect(flash[:error]).to eq 'Unable to run batch, please try again later.'
          expect(assigns[:batch].pids).to eq ['pid:1']
          expect(assigns[:batch]).to be_new_record
          expect(response).to redirect_to(request.referer)
        end
      end
    end
  end
end

require 'spec_helper'

describe Batch::ExportsController do
  let(:batch_export) { create(:batch_export) }

  context "non admin" do
    it 'denies access to create' do
      post :create
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'denies access to show' do
      get :show, id: batch_export
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'denies access to download' do
      get :show, id: batch_export
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "an admin" do
    let(:user) { create(:admin) }
    before do
      sign_in user
    end

    describe 'GET #download' do
      context "happy path" do
        it "sends the file" do
          allow(BatchExport).to receive(:find).with("42") { mock_model(BatchExport, id: 42) }

          get :download, id: 42

          expect(response.status).to eq(200)
          expect(response.headers["Content-Disposition"]).to eq('attachment; filename="batch_42.xml"')
        end
      end
    end

    describe "POST 'create'" do

      context "happy path" do
        let(:different_user) { create(:admin) }

        it 'creates a batch' do
          expect_any_instance_of(BatchExportRunnerService).to receive(:run) { true }
          expect {
            post 'create', pids: ["tufts:1", "tufts:2"]
          }.to change { Batch.count }.by(1)
          expect(assigns[:batch]).to be_kind_of BatchExport
          expect(assigns[:batch].creator).to eq controller.current_user
          expect(response).to redirect_to(assigns[:batch])
        end
      end

      context 'error path - no pids were selected:' do
        let(:attrs) { attributes_for(BatchExport, pids: []) }

        context "with a referrer" do
          before { allow(controller.request).to receive(:referer) { catalog_index_path } }

          it 'redirects to previous page' do
            allow(controller.request).to receive(:referer) { catalog_index_path }
            post :create, batch_export: attrs
            expect(response).to redirect_to(request.referer)
            expect(flash[:error]).to eq 'Please select some records to do batch updates.'
          end
        end

        context "with no referrer" do
          it 'redirects to root' do
            post :create, batch_export: attrs
            expect(response).to redirect_to(root_path)
            expect(flash[:error]).to eq 'Please select some records to do batch updates.'
          end
        end
      end

      context "error path - service fault" do
        before { allow(controller.request).to receive(:referer) { catalog_index_path } }

        it "redirects to previous page" do
          allow_any_instance_of(BatchExport).to receive(:save) { true }
          allow_any_instance_of(BatchExportRunnerService).to receive(:run) { false }
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

    describe "GET 'show'" do
      let(:batch_export) { FactoryGirl.create(:batch_export) }

      context 'happy path' do
        let(:records) { [double(pid: 'tufts:my-pid'), double(pid: 'tufts:another-pid')] }

        before do
          allow(ActiveFedora::Base).to receive(:find).with('tufts:my-pid', { cast: true }).and_return(records.first)
          allow(ActiveFedora::Base).to receive(:find).with('tufts:another-pid', { cast: true }).and_return(records.last)
        end

        it "returns http success" do
          get :show, id: batch_export.id
          expect(response).to be_success
          expect(response).to render_template(:show)
          expect(assigns[:batch].id).to eq batch_export.id
          expect(assigns[:batch]).to be_kind_of BatchExportPresenter
          expect(assigns[:batch].item_count).to eq(2)
        end
      end

    end

  end
end


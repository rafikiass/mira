require 'spec_helper'

shared_examples 'requires a list of pids' do |batch_factory|
  context 'error path - no pids were selected:' do
    context "with a referrer" do
      before { allow(controller.request).to receive(:referer) { catalog_index_path } }

      it 'redirects to previous page' do
        allow(controller.request).to receive(:referer) { catalog_index_path }
        post :create, batch: attributes_for(batch_factory, pids: [])
        expect(response).to redirect_to(request.referer)
      end
    end

    context "with no referrer" do
      it 'redirects to root' do
        post :create, batch: attributes_for(batch_factory, pids: [])
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to == 'Please select some records to do batch updates.'
      end
    end
  end
end


shared_examples 'batch creation happy path' do |batch_class|
  let(:factory_name) { batch_class.to_s.underscore.to_sym }
  let(:different_user) { create(:admin) }
  let(:service_name) { BatchRunnerService }

  it 'creates a batch' do
    expect_any_instance_of(service_name).to receive(:run) { true }
    expect {
      post 'create', batch: attributes_for(factory_name, creator_id: different_user.id)
    }.to change { Batch.count }.by(1)
    expect(assigns[:batch]).to be_kind_of batch_class
    expect(assigns[:batch].creator).to eq controller.current_user
    expect(response).to redirect_to(assigns[:batch])
  end
end


shared_examples 'batch run failure recovery' do |batch_class|
  let(:factory_name) { batch_class.to_s.underscore.to_sym }
  let(:attrs) { FactoryGirl.attributes_for(factory_name) }
  let(:service_name) { BatchRunnerService }

  context 'error path - batch fails to run:' do
    before do
      allow_any_instance_of(service_name).to receive(:run) { false }
    end

    it "doesn't create a batch object" do
      batch_class.any_instance.stub(:save) { true }
      expect {
        post :create, batch: attrs
      }.not_to change { Batch.count }
      expect(flash[:error]).to eq 'Unable to run batch, please try again later.'
      expect(assigns[:batch].pids).to eq attrs[:pids]
      expect(assigns[:batch]).to be_new_record
    end
  end
end


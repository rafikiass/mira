require 'spec_helper'

describe CuratedCollectionsController, if: Tufts::Application.til? do

  let(:image) { FactoryGirl.create(:image) }

  describe "for an unauthenticated user" do
    describe "create" do
      it "redirects to sign in" do
        post :create
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe "for an authenticated user" do
    let(:user) { FactoryGirl.create(:user) }
    before { sign_in user }

    describe "POST 'create'" do
      it "redirects" do
        post 'create', curated_collection: {title: 'foo'}
        expect(response.status).to eq 302
      end

      it "creates a CuratedCollection" do
        CuratedCollection.delete_all
        count = CuratedCollection.count
        post 'create', curated_collection: {title: 'foo'}
        expect(CuratedCollection.count).to eq (count + 1)
        expect(assigns[:curated_collection].managementType).to eq 'personal'
      end

      it 'uses the next sequence for the pid' do
        Sequence.where(name: nil, value: 100).create
        n = Sequence.where(name: 'curated_collection').first_or_create.value
        # if multiple sequences have the same value, this test doesn't test anything
        expect(Sequence.pluck(:value).uniq).to be_truthy

        post 'create', curated_collection: {title: 'foo'}
        expect(assigns[:curated_collection].pid).to eq "tufts:uc.#{n + 1}"
      end

      context 'with a bad title' do
        it "displays the form to fix the title" do
          count = CuratedCollection.count
          post 'create', curated_collection: {title: nil}
          expect(CuratedCollection.count).to eq count
          expect(response).to be_successful
          expect(response).to render_template(:new)
        end
      end
    end

    context "on an existing collection" do
      let(:collection) do
        FactoryGirl.create(:curated_collection,
                           user: user,
                           managementType: 'personal')
      end

      describe "GET 'show'" do
        it "returns http success" do
          get :show, id: collection.id
          expect(response).to be_successful
          expect(assigns[:curated_collection]).to eq collection
        end
      end

      describe "PATCH 'append_to'" do
        it "returns http success" do
          patch 'append_to', id: collection.id, pid: image.pid
          expect(response).to be_successful
          expect(collection.reload.members).to eq [image]
        end
      end
    end
  end

  describe "an admin user" do
    let(:admin) { FactoryGirl.create(:admin) }
    before { sign_in admin }

    describe "POST 'create'" do
      it "creates a course collection" do
        post 'create', curated_collection: {title: 'foo'}
        expect(assigns[:curated_collection].managementType).to eq 'curated'
      end
    end
  end
end

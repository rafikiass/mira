require 'spec_helper'

describe CatalogController do
  before do
    @user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
  end

  context 'a non-admin user' do
    before { sign_in @user }

    it 'denied access to catalog' do
      get :index
      response.should redirect_to(contributions_path)
    end

    it 'denied access to someone elses document' do
      not_my_doc = FactoryGirl.create(:tufts_pdf, user: @admin)
      get :show, id: not_my_doc.pid
      response.should redirect_to(root_path)
    end

    it 'has access to my own document' do
      my_doc = FactoryGirl.create(:tufts_pdf, user: @user)
      get :show, id: my_doc.pid
      response.should be_successful
      response.should render_template(:show)
    end
  end

  context 'an admin user' do
    before { sign_in @admin }

    it "should have #facet" do
      get :facet, id: 'names_sim'
      response.should be_successful
    end

    describe 'GET index' do
      it 'gets catalog' do
        get :index
        response.should be_successful
        response.should render_template(:index)
      end

      it "handles advanced searches with a 'format'" do
        good = FactoryGirl.create(:tufts_pdf, format: ['some format'])
        bad  = FactoryGirl.create(:tufts_pdf, format: ['other format'])
        get :index, search_field: :advanced, format_attr: 'some format'
        found = assigns[:document_list].map(&:id)
        expect(found).to include good.id
        expect(found).to_not include bad.id
      end

      context 'with both draft and published objects' do
        before do
          ActiveFedora::Base.delete_all
        end

        let!(:draft_record) do
          r = TuftsPdf.build_draft_version(displays: ['dl'], title: "orig title")
          r.save!
          r
        end

        let!(:published_record) do
          PublishService.new(draft_record).run
          TuftsPdf.find(PidUtils.to_published(draft_record.pid))
        end

        it 'displays only the draft records' do
          get :index
          records = assigns[:document_list].map(&:id)
          expect(records).to eq [draft_record.pid]
        end
      end
    end

    it 'can view someone elses document' do
      not_my_doc = FactoryGirl.create(:tufts_pdf, user: @user)
      get :show, id: not_my_doc.pid
      response.should be_successful
      response.should render_template(:show)
    end

    context 'viewing templates' do
      before { @excluded = FactoryGirl.create(:tufts_template) }
      after { @excluded.destroy }

      it 'filters from index' do
        get :index
        pid_list = assigns[:document_list].map {|doc| doc.id}
        expect(pid_list).not_to include(@excluded.pid)
      end
    end

  end

end

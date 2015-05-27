require 'spec_helper'

describe TemplatesController do
  before { sign_in user }

  describe 'as a non-admin user' do
    let(:user) { create(:user) }

    it 'redirects to contributions' do
      get :index
      expect(response).to redirect_to(contributions_path)
    end

  end

  describe 'as an admin user' do
    let(:user) { create(:admin) }

    context 'with some objects' do
      before do
        TuftsTemplate.destroy_all
        create(:tufts_template)
        create(:tufts_template)
        create(:tufts_pdf)
        create(:tufts_audio)
      end

      it 'returns only templates' do
        get :index
        expect(assigns[:document_list].count).to eq 2
      end
    end
  end
end

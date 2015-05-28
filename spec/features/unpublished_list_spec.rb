require 'spec_helper'

feature 'View unpublished documents' do

  context 'with published and unpublished objects' do

    before do
      TuftsAudio.where(title: "Very unique title").destroy_all
      sign_in :admin
    end

    let!(:published_audio_draft) do
      draft = TuftsAudio.build_draft_version(title: 'Very unique title', displays: ['dl'])
      draft.save!
      PublishService.new(draft).run
      draft
    end

    let!(:unpublished_audio_draft) do
      draft = TuftsAudio.build_draft_version(title: 'Very unique title', displays: ['dl'])
      draft.save!
      draft
    end


    scenario 'with a TuftsAudio' do
      visit root_path
      click_link 'Unpublished objects'

      fill_in 'q', with: 'Very unique title'
      click_button 'Search'

      page.should     have_link('Very unique title', href: catalog_path(unpublished_audio_draft) )
      page.should_not have_link('Very unique title', href: catalog_path(published_audio_draft) )
    end

    context 'with a TuftsTemplate' do
      before do
        TuftsTemplate.destroy_all
        @template = TuftsTemplate.new(template_name: 'My Template')
        @template.save!
        visit root_path
        click_link 'Unpublished objects'
      end

      after { @template.delete }

      it 'does not include the template in the results' do
        page.should     have_link('Very unique title', href: catalog_path(unpublished_audio_draft) )
        page.should_not have_link('My Template', href: catalog_path(@template) )
      end
    end

  end
end


feature "Finding self-deposited documents using facets" do
  before do
    ActiveFedora::Base.delete_all
    @self_deposit = FactoryGirl.create(:self_deposit_pdf)
    FactoryGirl.create(:tufts_pdf)
    sign_in :admin
  end
  after { ActiveFedora::Base.delete_all }

  it 'shows only the self-deposited docs' do
    visit unpublished_index_path
    within(".blacklight-deposit_method_ssi") do
      click_link 'self-deposit'
    end
    page.should have_css('#documents .document', count: 1) # filtered out all but one
    page.should have_link(@self_deposit.title, href: catalog_path(@self_deposit))
  end
end


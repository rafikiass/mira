require 'spec_helper'

feature 'Advanced Search' do

  before do
    ActiveFedora::Base.delete_all

    @fiction = TuftsPdf.build_draft_version(title: 'Space Detectives', genre: ['science fiction', 'fiction'], displays: ['dl'])
    @fiction.save!
    PublishService.new(@fiction).run

    @history = TuftsPdf.build_draft_version(title: 'Scientific Discoveries', genre: ['history', 'science'], displays: ['dl'])
    @history.save!
    PublishService.new(@history).run

    sign_in :admin
  end

  scenario 'search with AND' do
    visit root_path
    click_link 'Advanced Search'
    fill_in :genre, with: 'science AND history'
    click_button 'advanced_search'

    page.should     have_link('Scientific Discoveries', href: catalog_path(@history))
    page.should_not have_link('Space Detectives', href: catalog_path(@fiction))
  end

  scenario 'search with OR' do
    visit root_path
    click_link 'Advanced Search'
    fill_in :genre, with: 'science OR history'
    click_button 'advanced_search'

    page.should have_link('Scientific Discoveries', href: catalog_path(@history))
    page.should have_link('Space Detectives', href: catalog_path(@fiction))
  end

  scenario 'negative search' do
    visit root_path
    click_link 'Advanced Search'
    fill_in :genre, with: 'science -fiction'
    click_button 'advanced_search'

    page.should     have_link('Scientific Discoveries', href: catalog_path(@history))
    page.should_not have_link('Space Detectives', href: catalog_path(@fiction))
  end

  scenario "templates don't appear in facets" do
    FactoryGirl.create(:tufts_template)
    visit root_path
    click_link 'Advanced Search'
    within('#advanced_search_facets .blacklight-object_type_sim') do
      expect(page).to have_selector('li', count: 1)
      expect(page).to have_selector('li .facet_select', text: "Text")
      expect(page).to have_selector('li .facet-count', text: 4)
      expect(page).to_not have_content('Template')
    end
  end

  scenario "purged objects don't appear in facets" do
    PurgeService.new(@history).run

    visit root_path
    click_link 'Advanced Search'

    within('#advanced_search_facets .blacklight-object_type_sim') do
      expect(page).to have_selector('li', count: 1)
      expect(page).to have_selector('li .facet_select', text: "Text")
      expect(page).to have_selector('li .facet-count', text: 2)
    end
  end

end

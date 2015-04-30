require 'spec_helper'

feature 'Admin user purges document' do
  let(:audio) do
    TuftsAudio.build_draft_version(title: 'Very unique title', description: ['eh?'],
                                  creator: ['Fred'], displays: ['dl']).tap do |d|
      d.save!
    end
  end

  before do
    TuftsAudio.where(title: "Very unique title").destroy_all
    sign_in :admin
  end

  scenario 'with a TuftsAudio' do
    visit catalog_path(audio)
    click_link 'Purge'
    expect(page).to have_selector('div.alert', text: '"Very unique title" has been purged')

    fill_in 'q', with: 'Very unique title'
    click_button 'search'
    expect(page).to have_text('No entries found')
  end

end



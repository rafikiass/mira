require 'spec_helper'

feature 'Admin user edits document' do
  let(:audio) do
    TuftsAudio.build_draft_version(title: 'Test title', description: ['eh?'],
                                   creator: ['Fred'], displays: ['dl']).tap do |a|
      a.save!
    end
  end

  before { sign_in :admin }

  scenario 'with a TuftsAudio' do
    visit catalog_path(audio)
    click_link 'Edit Metadata'

    fill_in '*Title',      with: 'My title'
    fill_in 'Description', with: 'My desc'
    fill_in 'Creator',     with: 'Gillian'
    click_button 'Save'

    expect(page).to have_selector('h1', text: 'My title')
  end
end

require 'spec_helper'

feature 'Admin user creates document' do
  let(:pid)       { 'tufts:001.102.201' }
  let(:draft_pid) { 'draft:001.102.201' }

  before(:each) do
    sign_in :admin
    begin
      a = TuftsAudio.find(draft_pid)
      a.destroy
    rescue ActiveFedora::ObjectNotFoundError
    end
  end

  scenario 'with a TuftsAudio' do
    visit root_path
    click_link 'Create a new object'

    select "Audio", from: 'Select an object type'
    fill_in 'Title', with: 'My title'
    select 'dl', from: 'displays'
    fill_in 'Pid', with: pid
    click_button 'Next'

    # On the upload page
    expect(page).to have_selector('.file.btn', text: 'Upload ARCHIVAL_WAV')
    expect(page).to have_selector('input[type="file"].fileupload')
    expect(page).to have_selector('div.progress.progress-striped > .bar')
    click_button 'Next'

    fill_in '*Title', with: 'My title'
    select('dl', from: 'Displays in Portal')
    click_button 'Save'

    expect(page).to have_selector('div.alert', text: 'Object was successfully updated.')
  end

  scenario 'then purges it, recreates it, and it is properly marked Active in Fedora' do
    #TODO this should probably be a controller test as it would have less overhead
    # First create object
    visit root_path
    click_link 'Create a new object'

    select "Audio", from: 'Select an object type'
    fill_in 'Title', with: 'My title'
    select 'dl', from: 'displays'
    fill_in 'Pid', with: pid
    click_button 'Next'

    click_button 'Next'

    fill_in '*Title', with: 'My title to be purged'
    select('dl', from: 'Displays in Portal')
    click_button 'Save'

    expect(page).to have_selector('div.alert', text: 'Object was successfully updated.')

    # Now Purge it
    click_link 'Purge'
    expect(page).to have_selector('div.alert', text: '"My title to be purged" has been purged')

    # Now create another object with the recycled identifier
    visit root_path
    click_link 'Create a new object'

    select "Audio", from: 'Select an object type'
    fill_in 'Title', with: 'My title'
    select 'dl', from: 'displays'
    fill_in 'Pid', with: pid
    click_button 'Next'

    click_button 'Next'

    fill_in '*Title', with: 'My title to be recreated'
    select('dl', from: 'Displays in Portal')
    click_button 'Save'

    audio = TuftsAudio.find(draft_pid)
    expect(audio.state).to eq "A"
  end

end

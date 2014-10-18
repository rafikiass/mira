require 'spec_helper'

feature 'Admin user creates document' do
  before(:each) do
    sign_in :admin
    begin
      a = TuftsAudio.find('tufts:001.102.201')
      a.destroy
    rescue ActiveFedora::ObjectNotFoundError
    end
  end

  scenario 'with a TuftsAudio' do
    visit root_path
    click_link 'Create a new object'

    select "Audio", from: 'Select an object type'
    fill_in 'Pid', with: 'tufts:001.102.201'
    click_button 'Next'

    # On the upload page
    page.should have_selector('.file.btn', text: 'Upload ARCHIVAL_SOUND')
    page.should have_selector('input[type="file"].fileupload')
    page.should have_selector('div.progress.progress-striped.hidden > .bar')
    click_button 'Next'

    fill_in '*Title', with: 'My title'
    select('dl', from: 'Displays in Portal')
    click_button 'Save'

    page.should have_selector('div.alert', text: 'Object was successfully updated.')
  end

  scenario 'then purges it, recreates it, and it is properly marked Active in Fedora' do
    # First create object
    visit root_path
    click_link 'Create a new object'

    select "Audio", from: 'Select an object type'
    fill_in 'Pid', with: 'tufts:001.102.201'
    click_button 'Next'

    click_button 'Next'

    fill_in '*Title', with: 'My title to be purged'
    select('dl', from: 'Displays in Portal')
    click_button 'Save'

    page.should have_selector('div.alert', text: 'Object was successfully updated.')

    # Now Purge it
    click_link 'Purge'
    page.should have_selector('div.alert', text: '"My title to be purged" has been purged')

    # Now create another object with the recycled identifier
    visit root_path
    click_link 'Create a new object'

    select "Audio", from: 'Select an object type'
    fill_in 'Pid', with: 'tufts:001.102.201'
    click_button 'Next'

    fill_in '*Title', with: 'My title to be recreated'
    select('dl', from: 'Displays in Portal')
    click_button 'Save'
    
    audio = TuftsAudio.find('tufts:001.102.201')
    expect(audio.state).to eq "A"
  end


end

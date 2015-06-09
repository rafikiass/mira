require 'spec_helper'

feature 'Export datastreams' do
  let(:image) { FactoryGirl.create(:image) }

  before { sign_in :admin }

  scenario "from a record's show page", js: true do
    visit catalog_path(image)

    # Clicking 'Export Datastreams' makes the drop-down visible
    expect(page).to_not have_button 'Continue'
    click_link 'Export Datastreams'
    expect(page).to     have_button 'Continue'

    # Clicking 'Continue' submits the form to export datastreams
    expect(Job::Export).to receive(:create).once
    click_button 'Continue'

    # A batch was created to run the export job for this record
    within('.batch-items') do
      expect(page).to have_content image.pid
    end
  end

end

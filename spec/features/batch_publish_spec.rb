require 'spec_helper'

feature 'Publish multiple objects at once' do
  before do
    ActiveFedora::Base.delete_all
    sign_in :admin
  end

  let!(:car) { TuftsImage.create!(pid: 'draft:car', title: 'Picture of a Car', displays: ['dl']) }
  let!(:boat) { TuftsImage.create!(pid: 'draft:boat', title: 'Picture of a Boat', displays: ['dl']) }

  scenario 'select objects on search results page and publish them', js: true do
    visit root_path
    click_button 'Search'
    check('check_all')

    expect(Job::Publish).to receive(:create).twice
    click_button 'Publish'

    within('.batch-items') do
      expect(page).to have_content car.pid
      expect(page).to have_content boat.pid
    end
  end


  scenario 'select objects on unpublished page and publish them', js: true do
    visit unpublished_index_path
    check('check_all')

    expect(Job::Publish).to receive(:create).twice
    click_button 'Publish'

    within('.batch-items') do
      expect(page).to have_content car.pid
      expect(page).to have_content boat.pid
    end
  end
end

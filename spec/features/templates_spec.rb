require 'spec_helper'

describe 'Templates' do

  before :each do
    TuftsTemplate.delete_all
    sign_in :admin
    visit templates_path
  end

  it 'manages templates' do
    click_button 'New Template', match: :first
    fill_in 'Template name', with: "test template"
    click_button 'Save'

    #lists the templates
    expect(page).to have_content "Object was successfully updated"
    expect(page).to have_content "test template"

    # links to edit the templates
    click_link 'Edit'
    fill_in 'Template name', with: "Real template"
    click_button 'Save'

    expect(page).to have_content "Object was successfully updated"
    expect(page).to have_content "Real template"

    click_link 'Delete'

    expect(page).to have_content '"Real template" has been purged '
    within 'table' do
      expect(page).not_to have_content "Real template"
    end
  end
end

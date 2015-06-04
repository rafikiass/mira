require 'spec_helper'

describe 'Hitting the next button without selecting a file' do
  before do
    sign_in :admin
    visit new_batch_xml_import_path
    click_button 'Next'  # Without filling in the form
  end

  it 'displays error message' do
    expect(page).to have_content 'Please select a file'
  end
end

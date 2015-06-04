require 'spec_helper'

describe 'Template based import' do

  before do
    create :template_with_required_attributes, template_name: 'My template'
    sign_in :admin
    visit new_batch_template_import_path
  end

  it 'creates a batch templates' do
    select 'My template', from: 'Template'
    select 'PDF', from: 'Record type'
    click_button 'Next'
    expect(page).to have_content 'Select Files'
    attach_file 'documents_file_field', fixture_path + '/hello.pdf'
    click_button 'Start Upload'

    expect(page).to have_content 'Batch Status'
  end
end


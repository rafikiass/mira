require 'spec_helper'

feature 'Manage datastreams' do

  let(:pdf_file) { File.join(fixture_path, 'hello.pdf') }
  let(:transfer_file) { File.join(fixture_path, 'hello2.pdf') }

  let(:pdf) { 
    record = FactoryGirl.build(:pdf)
    record.add_file_datastream(File.open(pdf_file), dsid: 'Archival.pdf', mimeType: 'application/pdf')
    record.add_file_datastream(File.open(transfer_file), dsid: 'Transfer.binary', mimeType: 'application/pdf')
    record.save!
    record
  }

  before { sign_in :admin }


  scenario 'delete a datastream' do
    visit catalog_path(pdf)
    expect(page).to have_link('Download hello2.pdf')

    click_link 'Manage Datastreams'
    expect(page).to have_link('Remove', href: "/records/#{pdf.id}/attachments/Transfer.binary")

    click_link 'Remove'
    expect(page).to_not have_link('Download Transfer.binary')
  end

end

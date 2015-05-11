require 'spec_helper'

describe "batches/xml_import/new.html.erb" do
  let(:batch) { BatchXmlImport.new }
  before do
    assign :batch, batch
    render
  end

  it 'displays the form' do
    expect(rendered).to have_selector("form[method=post][action='#{batches_path}']")

    expect(rendered).to have_selector("input[type=hidden][name='batch[type]'][value=BatchXmlImport]")
    expect(rendered).to have_selector("input[type=file][name='batch[metadata_file]']")
  end

  context "with errors" do
    let(:batch) { BatchXmlImport.new.tap { |b| b.errors[:base] << "some error" } }

    it "displays errors" do
      expect(rendered).to have_selector(".alert li", text: "some error")
    end
  end
end

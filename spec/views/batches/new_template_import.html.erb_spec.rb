require 'spec_helper'

describe "batches/new_template_import.html.erb" do
  let(:batch) { BatchTemplateImport.new }
  let(:templates) { [build(:tufts_template), build(:tufts_template)] }

  before do
    allow(TuftsTemplate).to receive(:active).and_return templates
    assign :batch, batch
    render
  end

  it 'submits to batches#create' do
    expect(rendered).to have_selector("form[method=post][action='#{batches_path}']")
  end

  it 'displays the form to apply a template' do
    expect(rendered).to have_selector("input[type=hidden][name='batch[type]'][value=BatchTemplateImport]")
    expect(rendered).to have_selector("select[name='batch[template_id]']")
    templates.each do |t|
      rendered.should have_selector("option[value='#{t.id}']")
    end
    expect(rendered).to have_selector("select[name='batch[record_type]']")
  end

  context "with errors" do
    let(:batch) { BatchTemplateImport.new { |b| b.errors[:base] << "some error" } }

    it "displays errors" do
      expect(rendered).to have_selector(".alert li", text: "some error")
    end
  end
end

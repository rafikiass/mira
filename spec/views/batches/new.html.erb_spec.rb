require 'spec_helper'

describe "batches/new.html.erb" do
  let!(:templates) { [
      FactoryGirl.create(:tufts_template),
      FactoryGirl.create(:tufts_template)
    ] }
  let(:pids) { ["tufts:1", "tufts:2"] }
  let(:batch) { Batch.new(pids: pids, type: 'BatchTemplateUpdate') }

  before do
    assign :batch, batch
    render
  end

  it 'displays the form' do
    expect(rendered).to have_selector("form[method=post][action='#{batches_path}']")

    expect(rendered).to have_selector("input[type=hidden][name='batch[type]'][value=BatchTemplateUpdate]")
    expect(rendered).to have_selector("select[name='batch[template_id]']")
    pids.each do |pid|
      expect(rendered).to have_selector("input[type=hidden][name='batch[pids][]'][value='#{PidUtils.to_draft(pid)}']")
    end
    templates.each do |t|
      expect(rendered).to have_selector("option[value='#{t.id}']")
    end

    expect(rendered).to have_selector("input[type=radio][value='#{BatchTemplateUpdate::PRESERVE}'][name='batch[behavior]'][checked='checked']")
    expect(rendered).to have_selector("input[type=radio][value='#{BatchTemplateUpdate::OVERWRITE}'][name='batch[behavior]']")
  end
end

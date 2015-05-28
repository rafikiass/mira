require 'spec_helper'

describe 'Templates' do

  describe 'index page' do
    let! (:tmpl1) { create(:tufts_template) }
    let! (:tmpl2) { create(:tufts_template) }
    let! (:pdf1 ) { create(:tufts_pdf) }
    let! (:aud1 ) { create(:tufts_audio) }

    before :each do
      sign_in :admin
      visit templates_path
    end

    it 'draws the page' do
      expect(page).to have_selector("a[href='#{hydra_editor.new_record_path(type: 'TuftsTemplate')}']", count: 3 )
      expect(find("#main-container")).to have_link("Home")

      #lists the templates
      expect(page).to have_content(tmpl1.pid)
      expect(page).to have_content(tmpl2.pid)

      # does not list other object types
      expect(page).not_to have_content(pdf1.pid)
      expect(page).not_to have_content(aud1.pid)

      # links to edit the templates
      expect(page).to have_link('Edit', href: HydraEditor::Engine.routes.url_helpers.edit_record_path(tmpl1.pid))
      expect(page).to have_link('Edit', href: HydraEditor::Engine.routes.url_helpers.edit_record_path(tmpl2.pid))

      # links to delete the templates
      expect(page).to have_link('Delete', href: record_path(id: tmpl1.pid))
      expect(page).to have_link('Delete', href: record_path(id: tmpl2.pid))
    end
  end
end

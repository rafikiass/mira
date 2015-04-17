module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def link_to_edit(solr_doc)
    pid = PidUtils.to_draft(solr_doc.id)
    link_to "Edit Metadata", hydra_editor.edit_record_path(pid)
  end

end

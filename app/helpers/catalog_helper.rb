module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def link_to_edit(solr_doc)
    pid = PidUtils.to_draft(solr_doc.id)
    link_to "Edit Metadata", hydra_editor.edit_record_path(pid)
  end

  def workflow_status_indicator(document, options = {})
    css_classes = ['workflow-status', document.workflow_status]
    css_classes << options[:class] if options[:class].present?

    content_tag(:span, document.workflow_status, class: css_classes)
  end

  def enable_show_dl_link?(solr_doc)
    solr_doc.published? || solr_doc.workflow_status == :edited
  end

end

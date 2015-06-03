module BatchesHelper

  def batch_action_button(title, path, batch, options)
    form_tag(path) do
      content_tag(:div) do
        submit_tag(title, { class: 'btn btn-primary' }.merge(options)) +
        hidden_pids(batch)
      end
    end
  end

  def make_dl(title, value, css_class)
    content_tag(:dl, class: "dl-horizontal " + css_class) do
      content_tag(:dt) { title } + content_tag(:dd) { value.to_s }
    end
  end

  def batch_export_download_link(batch)
    batch.status == :completed ? link_to(BatchExportFilename.new(batch.id).file_name, download_batch_export_url(batch)) : 'XML file will be available for download when export is complete'
  end

  private
    def hidden_pids(batch)
      safe_join(batch.pids.map { |pid| hidden_field_tag('pids[]', pid) } )
    end
end

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

  def batch_status_text(batch)
    batch.status == :not_available ? 'Status not available' : batch.status.to_s.capitalize
  end

  def batch_export_download_link(batch)
    batch.status == :completed ? link_to(BatchExportFilename.new(batch.id).file_name, download_batch_export_url(batch)) : 'XML file will be available for download when export is complete'
  end

  def job_status_text(batch, job)
    if job.nil?
      if batch.created_at <= Resque::Plugins::Status::Hash.expire_in.seconds.ago
        'Status expired'
      else
        'Status not available'
      end
    else
      job.status.capitalize
    end
  end

  def line_item_status(batch, job, record_id=nil)
    if batch.is_a?(BatchTemplateImport) || batch.is_a?(BatchXmlImport)
      record_exists = record_id && ActiveFedora::Base.exists?(record_id)
      record_exists ? 'Completed' : 'Status not available'
    else
      job_status_text(@batch, job)
    end
  rescue => e
    Rails.logger.info("ERROR in line_item_status: #{e.message}")
    'Status not available'
  end

  def item_count(batch)
    batch.job_ids.present? ?  batch.job_ids.count : batch.pids.count
  end

  private
    def hidden_pids(batch)
      safe_join(batch.pids.map { |pid| hidden_field_tag('pids[]', pid) } )
    end
end

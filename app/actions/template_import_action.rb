class TemplateImportAction < BatchImportAction

  #TODO add transaction around batch. Is this needed?
  #TODO add transaction around everything? Is this possible?
  def run
    attrs = @batch.template.attributes_to_update.merge(batch_id: [@batch.id.to_s])
    record_class = @batch.record_type.constantize

    @document_statuses = @documents.map do |doc|
      record = if record_class.respond_to?(:build_draft_version)
                 record_class.build_draft_version(attrs)
               else
                 record_class.new(attrs)
               end
      save_record_with_document(record, doc)
      [doc, record, collect_warning(record, doc), nil]
    end
    docs, records, warnings, errors = @document_statuses.transpose

    @batch.pids = (@batch.pids || []) + records.compact.map(&:pid)
    @successful = @batch.save &&  # our batch saved
      errors.compact.empty? &&   # we have no errors from building records
      records.all?(&:persisted?) # all our records saved
  end
end

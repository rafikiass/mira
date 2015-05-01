class XmlBatchImportAction < BatchImportAction
  def run
    save_status = nil
    @document_statuses = @documents.map do |doc|
      record, warning, error = nil, nil, nil
      if @batch.uploaded_files.keys.include? doc.original_filename
        [doc, record, warning, "#{doc.original_filename} has already been uploaded"]
      else
        begin
          record = MetadataXmlParser.build_record(@batch.metadata_file.read, doc.original_filename)
          record.batch_id = [@batch.id.to_s]
          # TODO we need to know which datastream it should go to.
          saved = save_record_with_document(record, doc)
          warning = collect_warning(record, doc)
          save_status = save_attached_files(record, doc) if saved
        rescue MetadataXmlParserError => e
          error = e.message
        end
        [doc, record, warning, error]
      end
    end
    docs, records, warnings, errors = @document_statuses.transpose

    @successful = save_status &&  # our batch saved
      errors.compact.empty? &&   # we have no errors from building records
      records.all?(&:persisted?) # all our records saved
  end

  # TODO this is a mess because we have to ensure only one procss is writing to the database row at a time.
  # This method has a side effect of reloading @batch
  def save_attached_files(record, doc)
    save_status = nil
    Batch.transaction do
      @batch = Batch.lock.find(@batch.id) #reload batch within the transaction
      @batch.uploaded_files[doc.original_filename] = record.pid
      save_status = @batch.save
    end
    save_status
  end
end

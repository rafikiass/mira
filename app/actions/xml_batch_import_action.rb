class XmlBatchImportAction < BatchImportAction
  def run
    save_status = nil
    @document_statuses = @documents.map do |doc|
      record, warning, error = nil, nil, nil
      if @batch.uploaded_files.map(&:filename).include? doc.original_filename
        [doc, record, warning, "#{doc.original_filename} has already been uploaded"]
      else
        begin
          record = MetadataXmlParser.build_record(@batch.metadata_file.read, doc.original_filename)
          record.batch_id = [@batch.id.to_s]
          # TODO we need to know which datastream it should go to.
          saved = save_record_with_document(record, doc)
          warning = collect_warning(record, doc)
          save_attached_files(record, doc) if saved
        rescue MetadataXmlParserError => e
          error = e.message
        end
        [doc, record, warning, error]
      end
    end
    docs, records, warnings, errors = @document_statuses.transpose

    @successful = errors.compact.empty? &&   # we have no errors from building records
      records.all?(&:persisted?) # all our records saved
  end

  def save_attached_files(record, doc)
    UploadedFile.create!(batch: @batch, filename: doc.original_filename, pid: record.pid)
    @batch.uploaded_files(true) #refresh the uploaded_files association
  end
end

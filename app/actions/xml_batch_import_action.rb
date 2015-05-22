class XmlBatchImportAction < BatchImportAction
  def run
    save_status = nil
    parser = MetadataXmlParser.new(@batch.metadata_file.read)
    @document_statuses = @documents.map do |doc|
      record, warning, error = nil, nil, nil
      uploaded_files = @batch.uploaded_files(true).map(&:filename)
      if uploaded_files.include? doc.original_filename
        [doc, record, warning, "#{doc.original_filename} has already been uploaded"]
      else
        begin
          #TODO this could be find or build record, because there could be more than one file.
          record = parser.build_record(doc.original_filename)
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

    # we have no errors from building records and all our records saved
    errors.compact.empty? && records.all?(&:persisted?)
  end

  def save_attached_files(record, doc)
    UploadedFile.create!(batch: @batch, filename: doc.original_filename, pid: record.pid)
    @batch.uploaded_files(true) #refresh the uploaded_files association
  end
end

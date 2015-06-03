class BatchImportAction

  attr_reader :document_statuses, :current_user, :batch

  def initialize(batch, current_user, documents)
    @batch = batch
    @current_user = current_user
    @documents = documents
    @document_statuses = []
  end

  # Return a warning if the file is the wrong type for the given record/dsid
  # @param [#valid_type_for_datastream?] record the record to check
  # @param [String] dsid the datastream identifier
  # @param [File] doc the document to check
  def collect_warning(record, dsid, doc)
    if !record.valid_type_for_datastream?(dsid, doc.content_type)
      "You provided a #{doc.content_type} file, which is not a valid type for: #{dsid}"
    end
  end

end

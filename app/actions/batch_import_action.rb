class BatchImportAction

  attr_reader :document_statuses, :current_user, :batch

  def initialize(batch, current_user, documents)
    @batch = batch
    @current_user = current_user
    @documents = documents
    @document_statuses = []
  end

  def save_record_with_document(record, doc)
    dsid = record.class.original_file_datastreams.first
    record.working_user = current_user
    if record.save
      ArchivalStorageService.new(record, dsid, doc).run
      record.save # TODO investigate moving this save into ArchivalStorageService, because the service kicks off a job that operates on the datastream, which is not saved yet.
    else
      false
    end
  end

  def collect_warning(record, doc)
    dsid = record.class.original_file_datastreams.first
    if !record.valid_type_for_datastream?(dsid, doc.content_type)
      "You provided a #{doc.content_type} file, which is not a valid type: #{doc.original_filename}"
    end
  end

end

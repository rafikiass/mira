class XmlBatchImportAction < BatchImportAction
  # This method sets up the @document_statuses ivar, which is accessed externally
  def run
    save_status = nil
    parser = MetadataXmlParser.new(@batch.metadata_file.read)

    check_for_unknown_files(parser.filenames)
    check_for_duplicates

    records_with_all_uploaded_files(parser.records, uploaded_filenames).each do |record|
      create_model(record)
    end
    @batch.save
    docs, records, warnings, errors = document_statuses.transpose

    # we have no errors from building records and all our records saved
    errors.compact.empty? && records.all?(&:persisted?)
  end

  private

    # @param [ImportRecord] record
    def create_model(record)
      model = record.build_model
      model.batch_id = [@batch.id.to_s]
      saved = model.save # This ensures we get a pid.
      record.files.each do |dsid, filename|
        create_file(model, dsid, filename)
      end
      model.working_user = current_user
      saved = model.save
      Job::CreateDerivatives.create(record_id: model.pid) if saved
    end

    # @param [ActiveFedora::Base] model
    # @param [String] dsid The datastream to attach the file to
    # @param [String] filename The name of the file to attach
    def create_file(model, dsid, filename)
      file = @documents.find { |d| d.original_filename == filename }
      ArchivalStorageService.new(model, dsid, file).run
      save_attached_files(model, file, dsid)
      warning = collect_warning(model, file)
      @document_statuses << [filename, model, warning, nil]
    rescue MetadataXmlParserError => e
      @document_statuses << [filename, model, warning, e.message]
    end

    # Add errors if uploaded file is not in the document.
    # @param [Array<String>] filenames_in_document a list of filenames specified in the xml document
    def check_for_unknown_files(filenames_in_document)
      missing_files = uploaded_filenames - filenames_in_document
      missing_files.each do |filename|
        @document_statuses << [filename, nil, nil, "#{filename} doesn't exist in the metadata file"]
      end
    end

    # Add errors if uploaded file was already uploaded.
    def check_for_duplicates
      previously_uploaded_files = @batch.uploaded_files.map(&:filename)
      non_uniq(previously_uploaded_files + uploaded_filenames).each do |uploaded_filename|
        @document_statuses << [uploaded_filename, nil, nil, "#{uploaded_filename} has already been uploaded"]
        uploaded_filenames.delete(uploaded_filename) if previously_uploaded_files.include? uploaded_filename
      end
    end

    def save_attached_files(record, doc, dsid)
      @batch.uploaded_files.build(filename: doc.original_filename, dsid: dsid, pid: record.pid)
    end

    def uploaded_filenames
      @uploaded_filenames ||= @documents.map(&:original_filename)
    end

    def records_with_all_uploaded_files(nodes, uploaded_filenames)
      nodes.select { |node| node.files_subset?(uploaded_filenames) }
    end

    def counts(filenames)
       filenames.each_with_object(Hash.new(0)) {|k, counts| counts[k] += 1 }
    end

    def non_uniq(filenames)
       counts = counts(filenames)
       filenames.select {|e| counts[e] > 1 }
    end

end

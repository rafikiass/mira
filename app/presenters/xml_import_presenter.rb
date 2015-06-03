# Presents an BatchXmlImport which doesn't have jobs, but has a metadata file and uploaded_files
class XmlImportPresenter < BatchPresenter
  delegate :missing_files, to: :@batch

  def item_count
    @batch.pids.count
  end

  def items
    @items ||= begin
      records = @batch.parser.records
      records.each_with_object([]) do |record, items|
        record.files.each do |dsid, filename|
          # The record may not have a pid, so see if we can get a pid from the uploaded_files first.
          uploaded_file = @batch.uploaded_files.detect { |uf| uf.filename == filename }
          pid = uploaded_file ? uploaded_file.pid : record.pid
          items << XmlImportItemStatus.new(@batch, pid, dsid, filename)
        end
      end
    end
  end

end

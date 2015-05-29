class BatchExportFilename
  def initialize(batch_id, export_directory = File.join(Settings.object_store_root, "export"))
    @batch_id = batch_id
    @export_directory = export_directory
  end

  attr_reader :batch_id, :export_directory

  def full_path
    File.join export_directory, file_name
  end

  def file_name
    "batch_#{@batch_id}.xml"
  end
end

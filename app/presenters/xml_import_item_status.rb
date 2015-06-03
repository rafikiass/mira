class XmlImportItemStatus < BatchItemStatus
  def initialize(batch, pid, dsid, filename)
    @batch = batch
    @pid = pid
    @dsid = dsid
    @filename = filename
  end

  def filename
    @filename
  end

  def status
    record_exists = @pid && ActiveFedora::Base.exists?(@pid)
    record_exists ? 'Completed' : 'Status not available'
  end

end

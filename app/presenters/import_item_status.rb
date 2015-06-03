class ImportItemStatus < BatchItemStatus
  def status
    record_exists = @pid && ActiveFedora::Base.exists?(@pid)
    record_exists ? 'Completed' : 'Status not available'
  end
end

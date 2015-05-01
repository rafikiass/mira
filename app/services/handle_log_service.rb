class HandleLogService < LogService
  def filename
    File.join(Rails.root, 'log', 'handle.log')
  end
end

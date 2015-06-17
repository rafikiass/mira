class BatchExportPresenter < BatchPresenter

  # only one job for the export, but we exported the number of pids in the batch
  def item_count
    @batch.pids.count
  end
end

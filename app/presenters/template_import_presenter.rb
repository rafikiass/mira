# Presents BatchTemplateImport which doesn't have any jobs
class TemplateImportPresenter < BatchPresenter

  def item_count
    @batch.pids.count
  end

  private
    def item_class
      ImportItemStatus
    end
end

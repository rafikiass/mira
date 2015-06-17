# Presents Batches that have jobs
class BatchPresenter
  def initialize(batch)
    @batch = batch
  end

  delegate :display_name, :id, :to_param, :creator, :created_at, :status, :pids, to: :@batch

  def items
    @items ||= pids.map { |pid| item_class.new(@batch, pid) }
  end

  def item_count
    @batch.job_ids.count
  end

  def review_status
    items.all? { |m| m.reviewed? } ? "Complete" : "Incomplete"
  end

  def status_text
    @batch.status == :not_available ? 'Status not available' : @batch.status.to_s.capitalize
  end

  def export?
    @batch.type == 'BatchExport'
  end

  def self.presenter_for(batch)
    {
      BatchTemplateImport => TemplateImportPresenter,
      BatchXmlImport => XmlImportPresenter,
      BatchExport => BatchExportPresenter
    }.fetch(batch.class, self).new(batch)
  end

  private

    def item_class
      BatchItemStatus
    end

end

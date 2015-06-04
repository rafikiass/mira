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
    items.all? { |m| m.try(:reviewed?) } ? "Complete" : "Incomplete"
  end

  def status_text
    @batch.status == :not_available ? 'Status not available' : @batch.status.to_s.capitalize
  end

  def export?
    @batch.type == 'BatchExport'
  end

  private

    def item_class
      BatchItemStatus
    end

end

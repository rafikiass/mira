class BatchItemStatus
  def initialize(batch, pid)
    @batch = batch
    @pid = pid
  end

  attr_reader :pid

  def job
    @job ||= @batch.jobs.select {|job| job && job.options && (job.options['record_id'] == @pid) }.first
  end

  def record
    @record ||= ActiveFedora::Base.find(@pid, cast: true)
  rescue ActiveFedora::ObjectNotFoundError
  end

  def record_title
    record.try(&:title)
  end

  # An Xml Import batch has one pids is mapped to the uploaded files
  def title
    pid
  end

  def review_status
    record.try(:reviewed?)
  end

  def status
    if job.nil?
      if @batch.created_at <= Resque::Plugins::Status::Hash.expire_in.seconds.ago
        'Status expired'
      else
        'Status not available'
      end
    else
      job.status.capitalize
    end
  end

end

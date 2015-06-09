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
    @record ||= load_record
  end

  def record_title
    record.title
  end

  # An Xml Import batch has one pids is mapped to the uploaded files
  def title
    pid
  end

  def reviewed?
    record.reviewed?
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

  private
  def load_record
    ActiveFedora::Base.find(@pid, cast: true)
  rescue ActiveFedora::ObjectNotFoundError
    NullRecord.new
  end

  class NullRecord
    def reviewed?
      false
    end

    def title
      ""
    end
  end
end


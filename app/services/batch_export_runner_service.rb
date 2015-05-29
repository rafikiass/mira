class BatchExportRunnerService < BatchRunnerService
  attr_reader :datastream_ids

  def initialize(batch, ds_ids = [])
    super(batch)

    @datastream_ids = ds_ids
  end

  private
  def create_jobs
    [
      job_type.create(job_attributes)
    ]
  end

  def job_attributes
    {
      user_id: batch.creator.id,
      record_ids: batch.pids,
      batch_id: batch.id,
      datastream_ids: datastream_ids
    }
  end
end

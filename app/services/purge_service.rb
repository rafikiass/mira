class PurgeService < WorkflowService
  def run
    msg = content_datastreams
    if destroy_published_version!
      audit("Purged published version | #{msg.inspect}")
    end

    if destroy_draft_version!
      audit("Purged draft version | #{msg.inspect}")
    end
  end

  private

    def content_datastreams
      object.datastreams.select { |dsid, ds| ds.external? && ds.dsLocation.present? }.map { |dsid, ds| LocalPathService.new(object, dsid).local_path }
    end
end

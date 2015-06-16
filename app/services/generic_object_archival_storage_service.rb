# A storage service just for TuftsGenericObject
class GenericObjectArchivalStorageService < ArchivalStorageService
  def run
    # Because many processes may be running this method simultaneously,
    # we put all the updates to GENERIC-CONTENT in a queue and only have one
    # worker on that queue. This prevents one process from wiping out the update
    # done by another process.
    Job::ManifestUpdate.create(pid: object.pid, link: write_file, mime_type: file.content_type, filename: file.original_filename)
  end

  private
    def path_service
      @path_service ||= GenericObjectPathService.new(object, dsid, extension, file.original_filename)
    end
end


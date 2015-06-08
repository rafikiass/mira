# A storage service just for TuftsGenericObject
class GenericObjectArchivalStorageService < ArchivalStorageService
  def run
    object.datastreams[dsid].tap do |ds|
      write_manifest(ds)
    end
    object.content_will_update = dsid
  end

  private
    # Write the manifest
    def write_manifest(ds)
      ds.item.link = write_file
      ds.item.mimeType = file.content_type
      ds.item.fileName = file.original_filename
    end

    def path_service
      @path_service ||= GenericObjectPathService.new(object, dsid, extension, file.original_filename)
    end
end


class ArchivalStorageService
  attr_reader :object, :dsid, :file

  def initialize(object, dsid, file)
    @object = object
    @dsid = dsid
    @file = file
  end

  def run
    object.datastreams[dsid].tap do |ds|
      if dsid == 'GENERIC-CONTENT'
        write_manifest(ds)
      else
        ds.dsLocation = remote_url
        ds.mimeType = file.content_type
      end
    end
    object.content_will_update = dsid
  end

  private
    # Write the manifest for a TuftsGenericObject
    def write_manifest(ds)
      ds.item.link = remote_url
      ds.item.mimeType = file.content_type
      ds.item.fileName = file.original_filename
    end

    def remote_url
      path_service = LocalPathService.new(object, dsid, extension)
      path_service.make_directory
      File.open(path_service.local_path, 'wb') do |f|
        f.write file.read
      end
      path_service.remote_url
    end

    def extension
      @extension ||= file.original_filename.split('.').last
    end
end

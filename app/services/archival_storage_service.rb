class ArchivalStorageService
  attr_reader :object, :dsid, :file

  def initialize(object, dsid, file)
    @object = object
    @dsid = dsid
    @file = file
  end

  def run
    object.datastreams[dsid].tap do |ds|
      ds.dsLocation = write_file
      ds.mimeType = file.content_type
      ds.checksum = nil
    end
    object.content_will_update = dsid
  end

  private

    # Writes the file to the local datastore
    # @return the remote URL of the file
    def write_file
      path_service.make_directory
      File.open(path_service.local_path, 'wb') do |f|
        f.write file.read
      end
      path_service.remote_url
    end

    def path_service
      @path_service ||= LocalPathService.new(object, dsid, extension)
    end

    def extension
      @extension ||= file.original_filename.split('.').last
    end
end

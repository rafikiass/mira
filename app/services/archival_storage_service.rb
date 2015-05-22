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
    end
    object.content_will_update = dsid
    object.save
    Job::CreateDerivatives.create(record_id: object.pid)
  end

  private
    def write_file
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

class GenericObjectPathService < LocalPathService
  attr_reader :filename
  def initialize(object, dsid, extension, filename)
    @filename = filename
    super(object, dsid, extension)
  end

  def local_path
    File.join(local_path_root, file_path)
  end

  def remote_url
    File.join(remote_root, file_path)
  end

  private

    # Return the local path where the file can be found.
    # @example
    #   svc.file_path
    #   # => /local_object_store/data01/tufts/sas/1234/generic/hello.pdf
    def file_path
      File.join(object.directory_for(dsid), filename)
    end
end

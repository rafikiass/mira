class ImportRecord
  attr_reader :node
  def initialize(node)
    @node = node
  end

  def filenames
    node.xpath('./file').map(&:content)
  end

  # @return [Hash] with dsid as the key and the file name as the value
  def files
    node.xpath('./file').each_with_object({}) do |file_node, h|
      h[dsid_for_node(file_node)] = file_node.content
    end
  end

  # we may not have a pid node
  def pid
    node.xpath('./pid').first.try(:content)
  end

  # Return true if any of this records files are included in the superset
  # @param [Array<String>] superset
  def files_subset?(superset)
    filenames.any? { |filename| superset.include?(filename) }
  end

  def build_model
    @model ||= build_record_service.run
  end

  def build_record_service
    @build_record_service ||= BuildRecordService.new(node)
  end

  private

    def dsid_for_node(file_node)
      datastream_attribute = file_node.attributes['datastream']
      datastream_attribute ? datastream_attribute.value : build_record_service.valid_record_class.default_datastream
    end
end

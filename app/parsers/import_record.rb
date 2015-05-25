class ImportRecord
  attr_reader :node
  def initialize(node)
    @node = node
  end

  def filenames
    node.xpath('./file').map(&:content)
  end

  def files
    node.xpath('./file').each_with_object({}) do |file_node, h|
      h[dsid_for_node(file_node)] = file_node.content
    end
  end

  # Return true if all of this records files are included in the superset
  # @param [Array<String>] superset
  def files_subset?(superset)
    filenames.all? { |filename| superset.include?(filename) }
  end

  def build_model
    @model ||= CreateRecordService.new(node).run
  end

  private
    def default_datastream
      @model.class.original_file_datastreams.first
    end

    def dsid_for_node(file_node)
      datastream_attribute = file_node.attributes['datastream']
      datastream_attribute ? datastream_attribute.value : default_datastream
    end
end

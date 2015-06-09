class ImportService
  def initialize(record:, batch:)
    @object = record
    @batch = batch
  end

  attr_accessor :object, :batch

  def record
    @record ||= file.xpath("//digitalObject[pid='#{@object.id}']").first
  end

  def file
    @file ||= Nokogiri::XML.parse(batch.metadata_file)
  end

  def run
    record.xpath('./datastream').each do |ds_node|
      dsid = ds_node.attributes['id'].value
      object.datastreams[dsid].content = ds_node.children.to_xml.strip
    end
    object.save!
  end
end

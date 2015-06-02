class ImportService
  def initialize(pid:, batch_id:)
    @pid = pid
    @batch_id = batch_id
  end

  def batch
    @batch ||= Batch.find(@batch_id)
  end

  def object
    @object ||= ActiveFedora::Base.find(@pid)
  end

  def record
    @record ||= file.xpath("//digitalObject[pid='#{@pid}']").first
  end

  def file
    @file ||= Nokogiri::XML.parse(batch.metadata_file)
  end

  def run
    record.xpath('./dataStream').each do |ds_node|
      dsid = ds_node.attributes['id'].value
      object.datastreams[dsid].content = ds_node.children.to_xml.strip
    end
    object.save!
  end
end

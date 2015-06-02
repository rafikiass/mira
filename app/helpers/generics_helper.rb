module GenericsHelper
  def generic_items(solr_doc)
    object = ActiveFedora::Base.load_instance_from_solr(solr_doc.id, solr_doc)
    ns = { 'oxns' => "http://www.fedora.info/definitions/" }
    generic_content = object.datastreams["GENERIC-CONTENT"].ng_xml.xpath('//oxns:item', ns)
    generic_content.each_with_index.map do |node, i|
      link = "/downloads/#{object.pid}/#{i}"
      { file_name: node.xpath('./oxns:fileName', ns).first.content,
        mime_type: node.xpath('./oxns:mimeType', ns).first.content,
        download_path: link }
    end
  end
end

require 'metadata_xml_parser' # for error classes

# Builds a new record (e.g. TuftsPdf, etc) when given a node with xml attributes.
#   example:
#   <digitalObject xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:admin="http://nils.lib.tufts.edu/dcaadmin/" xmlns:rel="info:fedora/fedora-system:def/relations-external#">
#       <pid>tufts:1</pid>
#       <file datastream="Archival.pdf">AK-Page4.pdf</file>
#       <file datastream="Transfer.binary">Anna Karenina.docx</file>
#       <rel:hasModel>info:fedora/cm:Text.PDF</rel:hasModel>
#       <dc:title>Anatomical tables of the human body.</dc:title>
#       <admin:displays>dl</admin:displays>
#   </digitalObject>
#
class BuildRecordService

  attr_reader :node

  # @param [Nokogiri::XML::Element] node
  def initialize(node)
    @node = node
  end

  # @return [ActiveFedora::Base] an instance of the appropriate type
  def run
    record_class = valid_record_class
    attrs = record_attributes(record_class)

    draft_pid = PidUtils.to_draft(attrs[:pid]) if attrs[:pid]

    if draft_pid && ActiveFedora::Base.exists?(draft_pid)
      record_class.find(draft_pid)
    elsif record_class.respond_to?(:build_draft_version)
      record_class.build_draft_version(attrs)
    else
      raise "#{record_class} doesn't implement build_draft_version"
    end
  end

  def valid_record_class
    class_uri = node_content("./rel:hasModel", "rel" => "info:fedora/fedora-system:def/relations-external#")
    raise NodeNotFoundError.new(node.line, '<rel:hasModel>', ParsingError.for(node)) unless class_uri
    record_class = ActiveFedora::Model.from_class_uri(class_uri)
    raise HasModelNodeInvalidError.new(node.line, "'#{record_class}' was not amongst the allowed types: #{valid_record_types.inspect}.", ParsingError.for(node) ) unless valid_record_types.include?(record_class.to_s)
    record_class
  end

  def valid_record_types
    HydraEditor.models - ['TuftsTemplate']
  end

  def rels_ext
    rels_ext = node.xpath("./rel:*", {"rel" => "info:fedora/fedora-system:def/relations-external#"}).map do |element|
      { 'relationship_name' => element.name.underscore.to_sym,
        'relationship_value' => element.content }
    end
    { 'relationship_attributes' => rels_ext }
  end

  def record_attributes(record_class)
    pid = node_content("./pid")
    result = pid.present? ? {:pid => pid} : {}
    # remove attributes that are relationships
    attribute_definitions = record_class.defined_attributes.select do |name, definition|
      definition.dsid != "RELS-EXT"
    end
    attributes = attribute_definitions.reduce(result) do |result, attribute|
      attribute_name, definition = attribute

      path_info = attribute_path(record_class, attribute_name)
      namespaces = path_info[:namespaces]
      xpath = "." + path_info[:xpath]

      # query the node for this attribute
      content = node_content(xpath, namespaces, record_class.multiple?(attribute_name))

      content.blank? ? result : result.merge(attribute_name => content)
    end
    attributes.merge(rels_ext)
  end


  def attribute_path(record_class, attribute_name)
    ds_class = record_class.defined_attributes[attribute_name].datastream_class
    {namespaces: namespaces(ds_class),
      xpath: ds_class.new.public_send(attribute_name).xpath}
  end

  def namespaces(datastream_class)
    namespaces = datastream_class.ox_namespaces.reduce({}) do |result, pair|
      k,v = pair
      result[k.gsub('xmlns:', '')] = v unless k == 'xmlns'
      result
    end

    # Hack to fix potential bug in datastream definitions.
    # See https://github.com/curationexperts/mira/issues/227#issuecomment-40148086
    # and https://github.com/curationexperts/tufts_models/issues/11
    if datastream_class == TuftsDcDetailed
      namespaces['dcterms'] = namespaces['dcterms'].gsub("http://purl.org/d/terms/", "http://purl.org/dc/terms/")
    end

    namespaces
  end


  def node_content(xpath, namespaces={}, multiple=false)
    content = node.xpath(xpath, namespaces).map(&:content)
    multiple ? content : content.first
  end

end

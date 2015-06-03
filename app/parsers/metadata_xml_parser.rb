class MetadataXmlParserError < StandardError
  def initialize(line=nil, details={})
    @line = line
    @details = details
    super(message)
  end

  def append_details
    @details.empty? ? "" : " (" + @details.map{|k,v| "#{k}: #{v}"}.join(", ") + ")"
  end
end

class NodeNotFoundError < MetadataXmlParserError
  def initialize(line, element, details={})
    @element = element
    super(line, details)
  end

  def message
    "Could not find #{@element} attribute for record beginning at line #{@line}" + append_details
  end
end

class HasModelNodeInvalidError < MetadataXmlParserError
  def initialize(line, message, details={})
    @msg = message
    super(line, details)
  end

  def message
    "Invalid data in <rel:hasModel> for record beginning at line #{@line}." + @msg + append_details
  end
end

class DuplicateFilenameError < MetadataXmlParserError
  def message
    "Duplicate filename found at line #{@line}" + append_details
  end
end

class DuplicatePidError < MetadataXmlParserError
  def message
    "Multiple PIDs defined for record beginning at line #{@line}" + append_details
  end
end

class InvalidPidError < MetadataXmlParserError
  def message
    "Invalid PID defined for record beginning at line #{@line}. Pids must be in this format: tufts:1231" + append_details
  end
end

class ModelValidationError < MetadataXmlParserError
  def initialize(line, error_message, details={})
    @error_message = error_message
    super(line, details)
  end

  def message
    "#{@error_message} for record beginning at line #{@line}" + append_details
  end
end

class FileNotFoundError < MetadataXmlParserError
  def initialize(filename, details={})
    @filename = filename
    super(details)
  end

  def message
    "#{@filename} doesn't exist in the metadata file" + append_details
  end
end

class MissingFilenameError < MetadataXmlParserError
  def message
    "Missing filename in file node at line #{@line}" + append_details
  end
end

class MetadataXmlParser
  def initialize(xml)
    @xml = xml
  end

  def doc
    @doc ||= Nokogiri::XML(@xml)
  end

  def filenames
    doc.xpath('//digitalObject/file').map(&:content)
  end

  def validate
    validate_blank_files
    validate_duplicate_filename
    validate_duplicate_pids
    validate_pids

    doc.xpath('//digitalObject').each do |digital_object|
      if self.class.file(digital_object).nil?
        errors << NodeNotFoundError.new(digital_object.line, '<file>', ParsingError.for(digital_object))
      end
      begin
        m = CreateRecordService.new(digital_object).run
        m.valid?
        m.errors.full_messages.each do |message|
          errors << ModelValidationError.new(digital_object.line, message, ParsingError.for(digital_object))
        end
      rescue MetadataXmlParserError => e
        errors << e
      end
    end

    errors
  end

  def build_record(document_filename)
    node = find_node_for_file(document_filename)

    CreateRecordService.new(node).run
  end

  def find_node_for_file(document_filename)
    node = doc.at_xpath("//digitalObject[child::file/text()='#{document_filename}']")
    return node unless node.nil?
    raise FileNotFoundError.new(document_filename)
  end

  def pids
    doc.xpath('//digitalObject/pid').map(&:content)
  end

  def records
    @records ||= doc.xpath('//digitalObject').map { |elem| ImportRecord.new(elem) }
  end

  class << self
    def file(node)
      node.xpath("./file").map(&:content).first
    end

  end

  private
  def validate_blank_files
    digital_objects = doc.xpath("//digitalObject")
    digital_objects.xpath("./file").each do |file_node|
      if file_node.text.blank?
        errors << MissingFilenameError.new(file_node.line)
      end
    end
  end

  def validate_duplicate_filename
    files = doc.xpath("//digitalObject/file/text()")
    files.group_by(&:content).values.map { |nodes| nodes.drop(1) }.flatten.each do |duplicate|
      errors << DuplicateFilenameError.new(duplicate.line, ParsingError.for(duplicate))
    end
  end

  def validate_duplicate_pids
    pid_text.group_by(&:content).values.map { |nodes| nodes.drop(1) }.flatten.each do |duplicate|
      errors << DuplicatePidError.new(duplicate.line, ParsingError.for(duplicate))
    end
  end

  def validate_pids
    pid_text.reject { |pid| TuftsBase.valid_pid?(pid.content) }.each do |invalid|
      errors << InvalidPidError.new(invalid.line, ParsingError.for(invalid))
    end
  end

  def errors
    doc.errors
  end

  def pid_text
    doc.xpath("//digitalObject/pid/text()")
  end

end


class MetadataImportParser
  attr_reader :errors
  ALLOWED_DSIDS = Set['DCA-META', 'DCA-DETAIL-META', 'DCA-ADMIN', 'RELS-EXT']

  def initialize(file)
    @file = file
    @errors = []
  end

  def valid?
    validate
    errors.blank?
  end

  def pids
    document.xpath('//items/digitalObject/pid').map(&:content)
  end

  private

    def document
      @document ||= Nokogiri::XML.parse(@file)
    end

    def validate
      ensure_contains_digital_objects
      ensure_datastreams_are_valid
    end

    def ensure_contains_digital_objects
      unless document.xpath('//items/digitalObject').any?
        self.errors << "The file you uploaded doesn't contain any digital objects"
        return
      end
    end

    def ensure_datastreams_are_valid
      document.xpath('//items/digitalObject').each do |node|
        found = Set.new(node.xpath('./datastream/@id').map(&:value))
        unless found.subset? ALLOWED_DSIDS
          pid = node.xpath('./pid').first.content
          not_allowed = (found - ALLOWED_DSIDS).to_a.map(&:inspect).join(', ')
          self.errors << "The object #{pid} specifies the datastream: #{not_allowed} which is not allowed."
        end
      end
    end
end

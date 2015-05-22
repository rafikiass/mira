module ParsingError
  def self.for(node)
    record = node.at_xpath('ancestor-or-self::digitalObject')
    details = {}
    details[:file] = record.at_xpath('file').content if record.at_xpath('file').present?
    details[:pid] = record.at_xpath('pid').content if record.at_xpath('pid').present?
    details
  end
end

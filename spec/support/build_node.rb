  def build_node(overrides={})
    attributes = {
      "pid" => ["tufts:1"],
      "file" => ["anatomicaltables00ches.pdf"],
      "rel:hasModel" => ["info:fedora/cm:Text.PDF"],
      "dc:title" => ["Anatomical tables of the human body."],
      "admin:displays" => ["dl"],
      "dc:description" => ["Title page printed in red.",
                           "Several woodcuts signed by the monogrammist \"b\" appeared first in the Bible of 1490 translated into Italian by Niccol Malermi."],
    }.merge(overrides)

    attribute_xml = attributes.map do |attribute, values|
      values.map do |value|
        "<#{attribute}>#{value}</#{attribute}>"
      end.join("\n")
    end.join("\n")

    Nokogiri::XML('
  <digitalObject xmlns:dc="http://purl.org/dc/elements/1.1/"
                 xmlns:admin="http://nils.lib.tufts.edu/dcaadmin/"
                 xmlns:rel="info:fedora/fedora-system:def/relations-external#"
                 xmlns:oxns="http://purl.org/dc/elements/1.1/">
  ' + attribute_xml + '
  </digitalObject>').at_xpath("//digitalObject")
  end

require 'spec_helper'

describe MetadataXmlParser do
  before do
    allow(HydraEditor).to receive(:models).and_return(['TuftsPdf'])
  end
  let(:parser) { MetadataXmlParser.new(xml) }

  describe "::validate" do
    let(:errors) { parser.validate.map(&:message) }

    context "when there are no errors" do
      let(:xml) { build_node.to_xml }

      it "returns an empty array" do
        expect(parser.validate).to eq []
      end
    end

    context "with missing fields" do
      let(:xml) { build_node('dc:title' => [], 'admin:displays' => []).to_xml }
      it "finds ActiveFedora errors for each record" do
        expect(errors.sort.first).to match("Displays can't be blank for record beginning at line 1.*")
        expect(errors.sort.second).to match("Title can't be blank for record beginning at line 1.*")
      end
    end

    context "with invalid xml" do
      let(:xml) { '<foo></bar' }
      it "has errors" do
        expect(errors).to eq ["expected '>'", "Opening and ending tag mismatch: foo line 1 and bar"]
      end
    end

    context "without a model type (hasModel)" do
      let(:xml) { build_node('rel:hasModel' => []).to_xml }
      it "has errors" do
        expect(errors.first).to match /Could not find <rel:hasModel> .* line 1 .*/
      end
    end

    context "without a filename" do
      let(:xml) { build_node('file' => []).to_xml }
      it "has errors" do
        expect(errors.first).to match /Could not find <file> .* line 1/
      end
    end

    context "with duplicate filename" do
      let(:xml) { "<input>" +
        build_node('file' => ['foo.pdf']).to_xml +
        build_node('file' => ['foo.pdf']).to_xml +
        "</input>" }

      it "has errors" do
        expect(errors.first).to match /Duplicate filename found at line \d+/
      end
    end

    context "with duplicate pids" do
      let(:xml) { "<input>" +
        build_node('pid' => ['tufts:2'], 'file' => ['foo1.pdf']).to_xml +
        build_node('pid' => ['tufts:2'], 'file' => ['foo2.pdf']).to_xml +
        "</input>" }

      it "has errors" do
        expect(errors.first).to match /Multiple PIDs defined for record beginning at line \d+/
      end
    end

    context "with invalid pids" do
      let(:xml) { "<input>" +
        build_node('pid' => ['demo:FLORA:01.01'], 'file' => ['foo1.pdf']).to_xml +
        "</input>" }

      it "has errors" do
        expect(errors.first).to match /Invalid PID defined for record beginning at line \d+/
      end
    end
  end

  describe "::build_record" do
    let(:attributes) {{ 'pid' => ['tufts:1'],
                        'file' => ['somefile.pdf'],
                        'dc:title' => ['some title'],
                        'dc:description' => ['desc 1', 'desc 2']
    }}

    context "happy path" do
      let(:xml) { build_node(attributes).to_xml }

      it "builds a draft record that has the given filename" do
        m = parser.build_record(attributes['file'].first)

        expect(m.pid).to eq 'draft:1' # draft version of given pid
        expect(m.title).to eq attributes['dc:title'].first
        expect(m.description).to eq attributes['dc:description']
      end
    end

    context "with a model that doesn't support draft versions" do
      before do
        allow(TuftsPdf).to receive(:respond_to?).with(:pid_namespace).and_call_original
        expect(TuftsPdf).to receive(:respond_to?).with(:build_draft_version).and_return(false)
      end

      let(:xml) { build_node(attributes).to_xml }

      it 'raises an error' do
        expect {
          parser.build_record(attributes['file'].first)
        }.to raise_error("TuftsPdf doesn't implement build_draft_version")
      end
    end

    context "with a filename that's not in the metadata" do
      let(:attributes) {{ 'file' => ['somefile.pdf'] }}
      let(:xml) { build_node(attributes).to_xml }

      it "raises an error" do
        expect { parser.build_record("fail") }.to raise_exception(FileNotFoundError)
      end
    end
  end

  describe "#filenames" do
    let(:xml) { "<input>" +
        build_node('file' => ['foo.pdf']).to_xml +
        build_node('file' => ['bar.pdf']).to_xml +
        "</input>"
    }

    it "finds all the filenames" do
      expect(parser.filenames).to eq ['foo.pdf', 'bar.pdf']
    end
  end

  describe "#pids" do
    let(:xml) { "<input>" +
        build_node('pid' => ['tufts:1']).to_xml +
        build_node('pid' => ['tufts:2']).to_xml +
        "</input>" }
    it "finds all the pids" do
      expect(parser.pids).to eq ['tufts:1', 'tufts:2']
    end
  end

  describe "::namespaces" do
    it "converts datastream namespaces to the format Nokogiri wants" do
      ns = MetadataXmlParser.namespaces(TuftsDcaMeta)
      expect(ns["dca_dc"]).to eq TuftsDcaMeta.ox_namespaces["xmlns:dca_dc"]
      expect(ns["dcatech"]).to eq TuftsDcaMeta.ox_namespaces["xmlns:dcatech"]
    end

    # if the typos in the namespaces get fixed, we can remove this test and
    # the corresponding code in MetadataXmlParser#namespaces
    it "doesn't modify namespaces if they have been fixed in the project" do
      ns = MetadataXmlParser.namespaces(TuftsDcDetailed)
      expect(ns["dcterms"]).to eq "http://purl.org/dc/terms/"
    end
  end

  describe ".record_attributes" do
    it "merges in the pid if it exists" do
      attributes = MetadataXmlParser.record_attributes(build_node(pid: ['tufts:1']), TuftsPdf)
      expect(attributes[:pid]).to eq 'tufts:1'
    end

    it "sets attributes even if a private method exists with the the attribute's name" do
      attributes = MetadataXmlParser.record_attributes(build_node('oxns:format' => ['foo']), TuftsPdf)
      expect(attributes['format']).to eq ['foo']
    end

    it "only returns attributes that were found" do
      attributes = MetadataXmlParser.record_attributes(build_node('oxns:format' => []), TuftsPdf)
      expect(attributes.has_key?('format')).to be_falsey
    end

    it "includes rels_ext attributes" do
      attributes = MetadataXmlParser.record_attributes(build_node("rel:hasEquivalent" => ["eq:1", "eq:2"]), TuftsPdf)
      eq_pids = attributes['relationship_attributes'].select{|x| x['relationship_name'] == :has_equivalent}.map{|x| x['relationship_value']}
      expect(eq_pids.sort).to eq ["eq:1", "eq:2"]
    end
  end

  describe ".node_content" do
    it "gets the content for a multi-value attribute from the given node" do
      d1 = 'Title page printed in red.'
      d2 = 'Several woodcuts signed by the monogrammist "b" appeared first in the Bible of 1490 translated into Italian by Niccol Malermi.'
      namespaces = {"oxns"=>"http://purl.org/dc/elements/1.1/"}
      xpath = ".//oxns:description"
      desc = MetadataXmlParser.node_content(build_node, xpath, namespaces, true)
      expect(desc).to eq [d1, d2]
    end

    it "gets the content for a single-value attribute from the given node" do
      expected_title = 'Anatomical tables of the human body.'
      namespaces = {"oxns"=>"http://purl.org/dc/elements/1.1/"}
      xpath = ".//oxns:title"
      title = MetadataXmlParser.node_content(build_node, xpath, namespaces)
      expect(title).to eq expected_title
    end
  end

  describe ".valid_record_class" do
    it "raises if <hasModel> doesn't exist" do
      expect{
        MetadataXmlParser.valid_record_class(node_with_only_pid)
      }.to raise_error(NodeNotFoundError, /Could not find <rel:hasModel> attribute for record beginning at line \d+/)
    end

    it "raises if the given model uri doesn't correspond to a record class" do
      expect{
        MetadataXmlParser.valid_record_class(node_with_bad_model)
      }.to raise_error(HasModelNodeInvalidError)
    end

    it "returns a class" do
      record_class = MetadataXmlParser.valid_record_class(build_node)
      expect(record_class).to eq TuftsPdf
    end
  end

  describe "::rels_ext" do
    let(:eq_pid_1) { "eq:1" }
    let(:eq_pid_2) { "eq:2" }

    it 'returns rels_ext in a format to build the record' do
      node = build_node("rel:hasEquivalent" => [eq_pid_1, eq_pid_2])
      rels_ext = MetadataXmlParser.rels_ext(node)
      eq_pids = rels_ext['relationship_attributes'].select{|x| x['relationship_name'] == :has_equivalent}.map{|x| x['relationship_value']}
      expect(eq_pids.sort).to eq [eq_pid_1, eq_pid_2].sort
    end
  end
end

def node_with_only_pid
  doc = Nokogiri::XML(<<-empty_except_pid)
<digitalObject xmlns:rel="info:fedora/fedora-system:def/relations-external#">
  <pid>tufts:1</pid>
</digitalObject>
  empty_except_pid
  node = doc.at_xpath("//digitalObject")
end

def node_with_bad_model
  doc = Nokogiri::XML(<<-bad_model)
<digitalObject xmlns:rel="info:fedora/fedora-system:def/relations-external#">
  <rel:hasModel>info:fedora/cm:Text.SomethingBad</rel:hasModel>
</digitalObject>
  bad_model
  node = doc.at_xpath("//digitalObject")
end

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


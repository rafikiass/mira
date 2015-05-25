require 'spec_helper'

describe CreateRecordService do
  let(:service) { CreateRecordService.new(node) }
  let(:node) { Nokogiri::XML(xml).at_xpath("//digitalObject") }
  let(:xml) { build_node.to_xml }

  describe "::namespaces" do
    it "converts datastream namespaces to the format Nokogiri wants" do
      ns = service.namespaces(TuftsDcaMeta)
      expect(ns["dca_dc"]).to eq TuftsDcaMeta.ox_namespaces["xmlns:dca_dc"]
      expect(ns["dcatech"]).to eq TuftsDcaMeta.ox_namespaces["xmlns:dcatech"]
    end

    # if the typos in the namespaces get fixed, we can remove this test and
    # the corresponding code in MetadataXmlParser#namespaces
    it "doesn't modify namespaces if they have been fixed in the project" do
      ns = service.namespaces(TuftsDcDetailed)
      expect(ns["dcterms"]).to eq "http://purl.org/dc/terms/"
    end
  end

  describe ".record_attributes" do
    subject { service.record_attributes(TuftsPdf) }
    context "when the pid exists" do
      let(:node) { build_node(pid: ['tufts:1']) }
      it "merges in the pid" do
        expect(subject[:pid]).to eq 'tufts:1'
      end
    end

    context "if a private method exists with the the attribute's name" do
      let(:node) { build_node('oxns:format' => ['foo']) }
      it "sets attributes" do
        expect(subject['format']).to eq ['foo']
      end
    end

    context "when some attributes aren't found" do
      let(:node) { build_node('oxns:format' => []) }
      it "only returns attributes that were found" do
        expect(subject.has_key?('format')).to be false
      end
    end

    context "with rels-ext attributes" do
      let(:node) { build_node("rel:hasEquivalent" => ["eq:1", "eq:2"]) }
      it "includes rels_ext attributes" do
        eq_pids = subject['relationship_attributes'].select{|x| x['relationship_name'] == :has_equivalent}.map{|x| x['relationship_value']}
        expect(eq_pids.sort).to eq ["eq:1", "eq:2"]
      end
    end
  end

  describe ".node_content" do
    it "gets the content for a multi-value attribute from the given node" do
      d1 = 'Title page printed in red.'
      d2 = 'Several woodcuts signed by the monogrammist "b" appeared first in the Bible of 1490 translated into Italian by Niccol Malermi.'
      namespaces = {"oxns"=>"http://purl.org/dc/elements/1.1/"}
      xpath = ".//oxns:description"
      desc = service.node_content(xpath, namespaces, true)
      expect(desc).to eq [d1, d2]
    end

    it "gets the content for a single-value attribute from the given node" do
      expected_title = 'Anatomical tables of the human body.'
      namespaces = {"oxns"=>"http://purl.org/dc/elements/1.1/"}
      xpath = ".//oxns:title"
      title = service.node_content(xpath, namespaces)
      expect(title).to eq expected_title
    end
  end

  describe ".valid_record_class" do
    context "when hasModel doesn't exist" do
      let(:node) { node_with_only_pid }
      it "raises an error" do
        expect{
          service.valid_record_class
        }.to raise_error(NodeNotFoundError, /Could not find <rel:hasModel> attribute for record beginning at line \d+/)
      end
    end

    context "when the given model uri doesn't correspond to a record class" do
      let(:node) { node_with_bad_model }
      it "raises an error" do
        expect{
          service.valid_record_class
        }.to raise_error(HasModelNodeInvalidError)
      end
    end

    it "returns a class" do
      record_class = service.valid_record_class
      expect(record_class).to eq TuftsPdf
    end
  end

  describe "::rels_ext" do
    let(:eq_pid_1) { "eq:1" }
    let(:eq_pid_2) { "eq:2" }
    let(:node) { build_node("rel:hasEquivalent" => [eq_pid_1, eq_pid_2]) }

    it 'returns rels_ext in a format to build the record' do
      rels_ext = service.rels_ext
      eq_pids = rels_ext['relationship_attributes'].select{|x| x['relationship_name'] == :has_equivalent}.map{|x| x['relationship_value']}
      expect(eq_pids.sort).to eq [eq_pid_1, eq_pid_2].sort
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

end

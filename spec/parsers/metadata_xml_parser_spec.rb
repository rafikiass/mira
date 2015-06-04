require 'spec_helper'

describe MetadataXmlParser do
  before do
    # tufts:1 is hardcoded into build_node(). We need to make sure the draft version
    # is not in the repo:
    ActiveFedora::Base.find('draft:1', cast: true).delete if ActiveFedora::Base.exists?('draft:1')

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

    context "file validation" do
      context "without a filename" do
        let(:xml) { "<input>" +
                    build_node('file' => ['']).to_xml +
                    "</input>" }

        it "has errors" do
          expect(errors.first).to match /Missing filename in file node at line 3/
        end
      end

      context "without a file node" do
        let(:xml) { build_node('file' => []).to_xml }

        it "has errors" do
          expect(errors.first).to match  /Could not find <file> attribute for record beginning at line 1 .*/
        end
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
end


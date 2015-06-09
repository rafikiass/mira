require 'spec_helper'

describe MetadataImportParser do
  describe "valid?" do
    let(:parser) { described_class.new(file) }
    let(:file) { File.open(path).read }

    context "with a valid file" do
      let(:path) { fixture_path + '/export/sample_export.xml' }
      it "is valid and has no errors" do
        expect(parser).to be_valid
        expect(parser.errors).to be_empty
      end
    end

    context "with a file that lacks digitalObjects" do
      let(:file) { "<derp/>" }
      it "isn't valid and has errors" do
        expect(parser).not_to be_valid
        expect(parser.errors).to eq ["The file you uploaded doesn't contain any digital objects"]
      end
    end

    context "with a file that lacks pids" do
      let(:file) { "<items><digitalObject/></items>" }
      it "isn't valid and has errors" do
        expect(parser).not_to be_valid
        expect(parser.errors).to eq ["Some of the digitalObjects don't have a pid"]
      end
    end

    context "with an invalid datastream" do
      let(:file) { "<items><digitalObject>
                      <pid>draft:12440</pid>
                      <datastream id=\"fake\" />
                   </digitalObject></items>" }

      it "isn't valid and has errors" do
        expect(parser).not_to be_valid
        expect(parser.errors).to eq ["The object draft:12440 specifies the datastream: \"fake\" which is not allowed."]
      end
    end
  end
end

require 'spec_helper'

describe CapstoneProject do

  it_behaves_like 'rels-ext collection and ead are the same'

  describe "validation" do
    describe "on degree" do
      it "should require a degree" do
        expect(subject).to_not be_valid
        expect(subject.errors[:degree]).to eq ["can't be blank"]
      end
    end
  end

  describe "description" do
    before do
      subject.degree = 'LLM'
      subject.description = 'student provided description'
    end

    it "should get prefixed" do
      expect(subject.tufts_pdf.description).to eq ["Submitted in partial fulfillment of the degree Masters of Law in International Law at the Fletcher School of Law and Diplomacy. Abstract: student provided description"]
    end
  end
end


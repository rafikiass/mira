require 'spec_helper'

describe Contribution do
  describe "validation" do
    describe "on title" do
      it "shouldn't permit a title longer than 250 chars" do
        subject.title = "Small batch street art jean shorts umami Terry Richardson chia. Readymade stumptown kogi Cosby sweater hashtag scenester. Semiotics beard fap High Life. Quinoa mustache salvia deep v, Shoreditch Tonx gluten-free forage banh mi Truffaut selfies Odd Future"
        subject.should_not be_valid
        subject.errors[:title].should == ['is too long (maximum is 250 characters)']
      end
      it "should require a title" do
        subject.should_not be_valid
        subject.errors[:title].should == ["can't be blank"]
      end
    end
    it "shouldn't permit an description longer than 2000 chars" do
        subject.description = "Small batch street art jean shorts umami Terry Richardson chia. Readymade stumptown kogi Cosby sweater hashtag scenester. Semiotics beard fap High Life. Quinoa mustache salvia deep v, Shoreditch Tonx gluten-free forage banh mi Truffaut selfies Odd Future" * 8
        subject.should_not be_valid
        subject.errors[:description].should == ['is too long (maximum is 2000 characters)']
    end
    it "should require an description" do
        subject.should_not be_valid
        subject.errors[:description].should == ["can't be blank"]
    end
    it "should require a creator" do
        subject.should_not be_valid
        subject.errors[:creator].should == ["can't be blank"]
    end
    it "should require an attachment" do
        subject.should_not be_valid
        subject.errors[:attachment].should == ["can't be blank"]
    end

  end

  it "should have 'subject'" do
      subject.subject = 'test subject'
      subject.subject.should == 'test subject'
  end

  it "stores the license name" do
    subject.license = ['License 1', 'License 2']
    subject.license.should == ['License 1', 'License 2']
  end

  describe "saving" do
    before do
      path = '/local_object_store/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf'
      subject.attachment = Rack::Test::UploadedFile.new("#{fixture_path}#{path}", 'application/pdf', false)
      subject.title = 'test title'
      subject.stub(:valid? => true)
    end
    it "should use the sequence for the pid" do
      pid = Sequence.next_val
      Sequence.should_receive(:next_val).and_return(pid)
      subject.save
      expect(subject.tufts_pdf.pid).to eq pid
    end
  end

  describe "with deposit_type" do
    before do
      @deposit_type = FactoryGirl.create(:deposit_type)
      attrs = FactoryGirl.attributes_for(:tufts_pdf).merge(deposit_type: @deposit_type, license: 'blerg')
      @contribution = Contribution.new(attrs)
      @contribution.save
    end

    it 'adds license data to the deposit' do
      expected_data = [@deposit_type.license_name, 'blerg'].sort
      @contribution.tufts_pdf.license.sort.should == expected_data
    end

    it 'adds collection and ead relationships' do
      expected_collection = /^.*isMemberOf rdf:resource=.tufts:UA069\.001\.DO\.#{@deposit_type.source}.*$/
      expected_ead = /^.*hasDescription rdf:resource=.tufts:UA069\.001\.DO\.#{@deposit_type.source}.*$/

      rels_ext = @contribution.tufts_pdf.rels_ext.content
      rels_ext.should =~ expected_collection
      rels_ext.should =~ expected_ead
    end
  end

end

require 'spec_helper'
require 'nokogiri'

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

  it "should have 'embargo'" do
    subject.embargo = '2023-06-12'
    subject.embargo.should == '2023-06-12'
  end

  it "should have 'subject'" do
      subject.subject = 'test subject'
      subject.subject.should == 'test subject'
  end

  it "stores the license name" do
    subject.license = ['License 1', 'License 2']
    subject.license.should == ['License 1', 'License 2']
  end

  it 'sets a parent collection' do
    subject.tufts_pdf.stored_collection_id.should == 'tufts:UA069.001.DO.PB'
  end

  it "returns ead and collection relationships when the collection object exists" do
    ead = find_or_create_ead('tufts:UA069.001.DO.PB')
    subject.tufts_pdf.ead.should == ead
    subject.tufts_pdf.collection.should == ead
  end

  describe "saving" do
    before do
      path = '/local_object_store/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf'
      subject.attachment = Rack::Test::UploadedFile.new("#{fixture_path}#{path}", 'application/pdf', false)
      subject.title = 'test title'
      subject.embargo = '6'
      subject.stub(:valid? => true)
    end

    it "should use the sequence for the pid" do
      pid = Sequence.next_val
      Sequence.should_receive(:next_val).and_return(pid)
      subject.save
      expect(subject.tufts_pdf.pid).to eq pid
    end

    it "has OAI item ID in the rels-ext" do
      subject.save
      expected_value = "oai:#{subject.tufts_pdf.pid}"
      rels_ext = Nokogiri::XML(subject.tufts_pdf.rels_ext.content)
      namespace = "http://www.openarchives.org/OAI/2.0/"
      prefix = rels_ext.namespaces.key(namespace).match(/xmlns:(.*)/)[1]
      rels_ext.xpath("//rdf:Description/#{prefix}:itemID").text.should == expected_value
    end

    it "should have a valid embargo date" do
      subject.save
      embargo_date = Time.parse(subject.tufts_pdf.embargo.first)
      future_date  = Time.now + 6.months

      expect(embargo_date).to be_within(1.minute).of future_date

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

    it 'sets a parent collection' do
      @contribution.tufts_pdf.stored_collection_id.should == 'tufts:UA069.001.DO.PB'
    end
  end

  it_behaves_like 'rels-ext collection and ead are the same'

end

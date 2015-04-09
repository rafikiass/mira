require 'spec_helper'

describe TuftsRCR do
  
  it 'has methods to support a draft version of the object' do
    expect(TuftsRCR.respond_to?(:build_draft_version)).to be_truthy
  end

  describe "with access rights" do
    before do
      @rcr = TuftsRCR.new(title: 'test rcr', displays: ['dl'])
      @rcr.read_groups = ['public']
      @rcr.save!
    end

    after do
      @rcr.destroy
    end

    let (:ability) {  Ability.new(nil) }

    it "should be visible to a not-signed-in user" do
      ability.can?(:read, @rcr.pid).should be_truthy
    end
  end

end

require 'spec_helper'

describe TuftsEAD do

  it 'has methods to support a draft version of the object' do
    expect(TuftsEAD.respond_to?(:build_draft_version)).to be_truthy
  end

  describe "with access rights" do
    before do
      @ead = TuftsEAD.new(title: 'test ead', displays: ['dl'])
      @ead.read_groups = ['public']
      @ead.save!
    end

    after do
      @ead.destroy
    end

    let (:ability) {  Ability.new(nil) }

    it "should be visible to a not-signed-in user" do
      ability.can?(:read, @ead.pid).should be_truthy
    end
  end
end

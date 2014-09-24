require 'spec_helper'

describe TuftsFacultyPublication do

  describe "with access rights" do
    before do
      @audio = TuftsFacultyPublication.new(title: 'test facpub', displays: ['dl'])
      @audio.read_groups = ['public']
      @audio.save!
    end

    after do
      @audio.destroy
    end

    let (:ability) {  Ability.new(nil) }

    it "should be visible to a not-signed-in user" do
      ability.can?(:read, @audio.pid).should be_truthy
    end
  end
end

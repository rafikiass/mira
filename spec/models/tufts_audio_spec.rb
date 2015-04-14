require 'spec_helper'

describe TuftsAudio do

  describe "with access rights" do
    before do
      @audio = TuftsAudio.new(title: 'foo', displays: ['dl'])
      @audio.read_groups = ['public']
      @audio.save!
    end

    after do
      @audio.destroy
    end

    let (:ability) {  Ability.new(nil) }

    it "should be visible to a not-signed-in user" do
      expect(ability.can?(:read, @audio.pid)).to be true
    end
  end
end

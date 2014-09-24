require 'spec_helper'

describe TuftsAudioText do
  describe "with access rights" do
    before do
      @audio_text = TuftsAudioText.new(title: 'new audio text', displays: ['dl'])
      @audio_text.read_groups = ['public']
      @audio_text.save!
    end

    after do
      @audio_text.destroy
    end

    let (:ability) {  Ability.new(nil) }

    it "should be visible to a not-signed-in user" do
      ability.can?(:read, @audio_text.pid).should be_truthy
    end
  end

end

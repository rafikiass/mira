require 'spec_helper'

describe RecordsHelper do
  describe "#object_type_options" do
    subject { helper.object_type_options }
    it { is_expected.to eq('Audio' => 'TuftsAudio',
       "Collection creator" => "TuftsRCR",
       "Collection guide" => "TuftsEAD",
       "Generic object" => "TuftsGenericObject",
       'Image' => 'TuftsImage',
       'PDF' => 'TuftsPdf',
       'TEI' => 'TuftsTEI',
       'Template' => 'TuftsTemplate',
       'Video' => 'TuftsVideo',
       'Voting Record' => 'TuftsVotingRecord') }
  end

  describe "#model_labels" do
    subject { helper.model_label(model) }

    context "TuftsAudio" do
      let(:model) { 'TuftsAudio' }
      it { is_expected.to eq 'audio' }
    end

    context "TuftsPdf" do
      let(:model) { 'TuftsPdf' }
      it { is_expected.to eq 'PDF' }
    end

    context "TuftsTemplate" do
      let(:model) { 'TuftsTemplate' }
      it { is_expected.to eq 'Template' }
    end
  end

  describe "sorted_object_types" do
    subject { helper.sorted_object_types }
    it { is_expected.to eq [["Audio", "TuftsAudio"],
                           ["Collection creator", "TuftsRCR"],
                           ["Collection guide", "TuftsEAD"],
                           ["Generic object", "TuftsGenericObject"],
                           ["Image", "TuftsImage"],
                           ["PDF", "TuftsPdf"],
                           ["TEI", "TuftsTEI"],
                           ["Video", "TuftsVideo"],
                           ["Voting Record", "TuftsVotingRecord"]] }
  end

  describe "displays_options" do
    subject { helper.displays_options }
    it { is_expected.to eq %w(nowhere dl trove tisch perseus elections) }
  end
end

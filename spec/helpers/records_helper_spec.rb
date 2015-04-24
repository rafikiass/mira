require 'spec_helper'

describe RecordsHelper do
  it "should have object_type_options" do
    helper.object_type_options.should == {'Audio' => 'TuftsAudio',
       "Collection creator" => "TuftsRCR",
       "Collection guide" => "TuftsEAD",
       "Generic object" => "TuftsGenericObject",
       'Image' => 'TuftsImage',
       'PDF' => 'TuftsPdf',
       'TEI' => 'TuftsTEI',
       'Template' => 'TuftsTemplate',
       'Video' => 'TuftsVideo',
       'Voting Record' => 'TuftsVotingRecord'}
  end

  it "should have model_labels" do
    helper.model_label('TuftsAudio').should == 'audio'
    helper.model_label('TuftsPdf').should == 'PDF'
    helper.model_label('TuftsTemplate').should == 'Template'
  end

  it 'has sorted object types' do
    options = helper.sorted_object_types
    expect(options).to eq [["Audio", "TuftsAudio"],
                           ["Collection creator", "TuftsRCR"],
                           ["Collection guide", "TuftsEAD"],
                           ["Generic object", "TuftsGenericObject"],
                           ["Image", "TuftsImage"],
                           ["PDF", "TuftsPdf"],
                           ["TEI", "TuftsTEI"],
                           ["Template", "TuftsTemplate"],
                           ["Video", "TuftsVideo"],
                           ["Voting Record", "TuftsVotingRecord"]]
  end

  describe "displays_options" do
    subject { helper.displays_options }
    it { is_expected.to eq %w(dl trove tisch perseus elections dark nowhere) }
  end
end

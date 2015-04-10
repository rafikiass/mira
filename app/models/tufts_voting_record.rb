require File.join(TuftsModels::Engine.root, 'app', 'models', 'tufts_voting_record')

class TuftsVotingRecord
  include DraftVersion
end

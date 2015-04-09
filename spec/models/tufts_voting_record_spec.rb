require 'spec_helper'

describe TuftsVotingRecord do

  it 'has methods to support a draft version of the object' do
    expect(TuftsVotingRecord.respond_to?(:build_draft_version)).to be_truthy
  end

end

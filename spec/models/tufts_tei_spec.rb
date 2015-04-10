require 'spec_helper'

describe TuftsTEI do
  it 'has methods to support a draft version of the object' do
    expect(TuftsTEI.respond_to?(:build_draft_version)).to be_truthy
  end
end

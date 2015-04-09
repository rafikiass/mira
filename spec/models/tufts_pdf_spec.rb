require 'spec_helper'

describe TuftsPdf do

  it 'has methods to support a draft version of the object' do
    expect(TuftsPdf.respond_to?(:build_draft_version)).to be_truthy
  end

end

require 'spec_helper'

describe Sequence do
  it "should have a format like tufts:sd.0000000" do
    n = Sequence.where(name: nil).first_or_create.value
    expect(Sequence.next_val).to eq "tufts:sd.000000#{n + 1}"
  end

  it "stores custom formats" do
    # if multiple sequences have the same value, this test doesn't test anything
    Sequence.where(name: 'some other name', value: 100).create
    expect(Sequence.pluck(:value).uniq).to be_truthy

    n = Sequence.where(name: 'curated_collection').first_or_create.value
    expect(Sequence.next_val(name: 'curated_collection', format: 'uc.%d')).to eq "tufts:uc.#{n + 1}"
  end
end

FactoryGirl.define do
  factory :tufts_audio do
    initialize_with { new(namespace: namespace) }

    transient do
      user { FactoryGirl.create(:user) }
      namespace { PidUtils.draft_namespace }
    end

    displays { ['dl'] }
    sequence(:title) {|n| "Title #{n}" }
    after(:build) { |deposit, evaluator|
      deposit.apply_depositor_metadata(evaluator.user.display_name)
    }
  end
end


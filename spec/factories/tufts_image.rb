FactoryGirl.define do
  factory :tufts_image, aliases: [:image] do
    transient do
      namespace { PidUtils.draft_namespace }
    end

    initialize_with { new(namespace: namespace) }

    displays { ['dl'] }
    sequence(:title) {|n| "Title #{n}" }
  end
end

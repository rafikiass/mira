FactoryGirl.define do
  factory :tufts_pdf, aliases: [:pdf] do
    initialize_with { new(namespace: namespace) }

    transient do
      namespace { PidUtils.draft_namespace }
      user { FactoryGirl.create(:user) }
    end

    sequence(:title) {|n| "Title #{n}" }
    displays { ['dl'] }
    after(:build) { |deposit, evaluator|
      deposit.apply_depositor_metadata(evaluator.user.display_name)
    }
    rights { ['http://dca.tufts.edu/ua/access/rights-creator.html'] }
  end

  factory :pdf_with_pid, parent: :tufts_pdf do
    initialize_with { new(pid: pid) }
  end

  factory :self_deposit_pdf, parent: :tufts_pdf do
    createdby Contribution::SELFDEP
    after(:build) do |deposit, evaluator|
      deposit.note = ["#{evaluator.user.display_name} self-deposited on #{Time.now.strftime('%Y-%m-%d at %H:%M:%S %Z')} using the Deposit Form for the Tufts Digital Library"]
    end
  end
end


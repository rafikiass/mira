FactoryGirl.define do
  factory :tufts_template do
    sequence(:template_name) {|n| "Template #{n}" }
    title "updated title"
    initialize_with { new(namespace: 'template') }

    factory :template_with_required_attributes do
      displays ['dl']
    end
  end
end

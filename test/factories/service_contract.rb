FactoryBot.define do

  factory :service_contract do
    sequence(:name) { |n| "name-#{n}"}
    sequence(:number) { |n| "number-#{n}"}
    sequence(:subject) { |n| "subject-#{n}"}
    sequence(:error_hours) { |n| "error_hours-#{n}"}
    association :author, factory: :user
    project
  end

end

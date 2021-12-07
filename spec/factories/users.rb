FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user-#{n}@example.com" }
    password { "my-secret" }
    confirmed_at { Time.now }
  end

  trait :unconfirmed do
    confirmed_at { nil }
  end
end

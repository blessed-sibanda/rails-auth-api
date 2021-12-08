FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { "user-#{SecureRandom.hex(4)}@example.com" }
    password { "my-secret" }
    confirmed_at { Time.now }
  end

  trait :unconfirmed do
    confirmed_at { nil }
  end

  trait :random do
    confirmed_at { [Time.now, nil].sample }
  end
end

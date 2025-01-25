FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    avatar_url { "https://example.com/avatar.jpg" }
    confirmed_at { nil }
    confirmation_sent_at { Time.current }
    failed_attempts { 0 }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :locked do
      failed_attempts { 5 }
      locked_at { Time.current }
    end
  end
end

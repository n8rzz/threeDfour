FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "#{Faker::Internet.unique.username}#{n}@#{Faker::Internet.domain_name}" }
    sequence(:username) { |n| "#{Faker::Internet.unique.username(specifier: 5..10)}#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    avatar_url { Faker::Avatar.image }
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

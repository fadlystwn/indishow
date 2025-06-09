FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :artist do
      role { 'artist' }
      after(:build) do |user|
        user.profile = build(:artist_profile, user: user)
      end
    end

    trait :fan do
      role { 'fan' }
      after(:build) do |user|
        user.profile = build(:fan_profile, user: user)
      end
    end
  end
end
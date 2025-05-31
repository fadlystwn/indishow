FactoryBot.define do
  factory :release do
    title { "My Album" }
    artist { "Test Artist" }
    release_type { 1 }
    release_date { Date.current }
    price { 9.99 }
    association :user
  end
end

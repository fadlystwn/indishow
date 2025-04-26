FactoryBot.define do
  factory :release do
    title { "My Album" }
    release_type { 1 }
    user { nil }
  end
end

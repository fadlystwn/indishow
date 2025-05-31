FactoryBot.define do
  factory :track do
    title { "Sample Track" }
    duration { 180 }
    position { 1 }
    association :release
  end
end

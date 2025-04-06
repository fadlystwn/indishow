FactoryBot.define do
  factory :album do
    association :user
    title { "Echoes of Tomorrow" }
    description { "A concept album blending electronic and acoustic sounds, exploring the theme of time." }
    cover_url { "https://example.com/covers/echoes-of-tomorrow.jpg" }
    release_date { Date.new(2025, 4, 6) }
    genre { "Electronic" }
    price_cents { 1299 }
  end
end

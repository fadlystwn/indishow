FactoryBot.define do
  factory :profile do
    sequence(:name) { |n| "Artist #{n}" }
    bio { "Sample bio for artist profile" }
    location { "New York, NY" }
    website_url { "https://example.com" }
    favorite_genres { 'rock,jazz' }

    factory :artist_profile, class: 'ArtistProfile' do
      type { 'ArtistProfile' }
    end

    factory :fan_profile, class: 'FanProfile' do
      type { 'FanProfile' }
    end
  end
end
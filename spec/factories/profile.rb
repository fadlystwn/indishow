FactoryBot.define do
  factory :profile do
    name { Faker::Name.name }
    bio { Faker::Lorem.paragraph }
    location { Faker::Address.city }
    website_url { Faker::Internet.url }
    favorite_genres { ['rock', 'jazz'] }

    factory :artist_profile, class: 'ArtistProfile' do
      type { 'ArtistProfile' }
    end

    factory :fan_profile, class: 'FanProfile' do
      type { 'FanProfile' }
    end
  end
end
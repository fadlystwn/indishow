FactoryBot.define do
  factory :release do
    title { "My Album" }
    artist { "Test Artist" }
    release_type { :single }
    release_date { Date.current }
    price { 9.99 }
    genre { "Rock" }
    status { "draft" }
    association :user

    transient do
      tracks_count { 0 }
    end

    trait :published do
      after(:create) do |release|
        # Create tracks based on release type if none exist
        if release.tracks.empty?
          case release.release_type
          when 'single'
            create(:track, release: release, position: 1, title: "Track 1")
          when 'ep'
            3.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}") }
          when 'album'
            8.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}") }
          when 'compilation'
            5.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}") }
          end
        end
        
        # Now update status to published
        release.update_column(:status, "published")
      end
    end

    trait :with_tracks do
      after(:create) do |release|
        case release.release_type
        when 'single'
          create(:track, release: release, position: 1, title: "Track 1")
        when 'ep'
          3.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}") }
        when 'album'
          8.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}") }
        when 'compilation'
          5.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}") }
        end
      end
    end

    trait :single do
      release_type { :single }
    end

    trait :ep do
      release_type { :ep }
    end

    trait :album do
      release_type { :album }
    end

    trait :compilation do
      release_type { :compilation }
    end
  end
end

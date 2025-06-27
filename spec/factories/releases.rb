FactoryBot.define do
  factory :release do
    title { "My Album" }
    artist { "Test Artist" }
    release_type { :single }
    release_date { Date.current }
    price { 9.99 }
    genre { "Rock" }
    status { "draft" }
    description { "An amazing release" }
    association :user

    transient do
      tracks_count { 0 }
    end

    trait :draft do
      status { "draft" }
    end

    trait :incomplete do
      title { "" }
      artist { "" }
    end

    trait :single do
      release_type { "single" }
      title { "Test Single" }
    end

    trait :ep do
      release_type { "ep" }
      title { "Test EP" }
    end

    trait :album do
      release_type { "album" }
      title { "Test Album" }
    end

    trait :compilation do
      release_type { "compilation" }
      title { "Test Compilation" }
    end

    trait :complete do
      title { "Complete Single" }
      artist { "Test Artist" }
      release_date { Date.current }
      genre { "Rock" }
      description { "A complete release ready for publishing" }
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

        release.update_column(:status, "published")
      end
    end

    trait :with_tracks do
      after(:create) do |release|
        case release.release_type
        when 'single'
          create(:track, release: release, position: 1, title: "Track 1", duration: 180)
        when 'ep'
          3.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}", duration: 180) }
        when 'album'
          8.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}", duration: 180) }
        when 'compilation'
          5.times { |i| create(:track, release: release, position: i + 1, title: "Track #{i + 1}", duration: 180) }
        end
      end
    end

    trait :with_cover_art do
      after(:build) do |release|
        release.cover_art.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'sample_image.jpg')),
          filename: 'sample_image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end

    # Factory combinations for common test scenarios
    factory :complete_single do
      single
      complete
      with_tracks
    end

    factory :complete_ep do
      ep
      complete
      with_tracks
    end

    factory :complete_album do
      album
      complete
      with_tracks
    end

    factory :incomplete_draft do
      draft
      incomplete
    end
  end
end

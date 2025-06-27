FactoryBot.define do
  factory :track do
    sequence(:title) { |n| "Track #{n}" }
    duration { 180 }
    sequence(:position)
    association :release

    trait :with_audio do
      after(:build) do |track|
        track.audio_file.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3')),
          filename: 'sample_audio.mp3',
          content_type: 'audio/mpeg'
        )
      end
    end

    trait :invalid do
      title { "" }
      duration { -1 }
    end

    trait :long do
      duration { 600 } # 10 minutes
    end

    trait :short do
      duration { 60 } # 1 minute
    end
  end
end

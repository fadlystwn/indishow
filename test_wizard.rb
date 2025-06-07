#!/usr/bin/env ruby

# Test script to verify the release wizard flow
require_relative 'config/environment'

# Get the artist user
artist = User.find_by(email: 'artist@example.com')
puts "Testing with artist: #{artist.email}"

# Test Step 1: Create draft release
puts "\n--- Step 1: Creating draft release ---"
release_draft = artist.releases.create!(
  release_type: 'single',
  status: 'draft'
)
puts "Created draft release: #{release_draft.id}"
puts "Release type: #{release_draft.release_type}"
puts "Status: #{release_draft.status}"

# Test Step 2: Update with release info
puts "\n--- Step 2: Updating release info ---"
update_params = {
  title: "Test Single",
  artist: artist.artist_profile.name,
  release_date: Date.current + 1.month,
  price: 9.99,
  description: "A test single for the wizard",
  genre: "Rock"
}

if release_draft.update(update_params)
  puts "✅ Release info updated successfully"
  puts "Title: #{release_draft.title}"
  puts "Artist: #{release_draft.artist}"
  puts "Release date: #{release_draft.release_date}"
  puts "Price: $#{release_draft.price}"
  puts "Genre: #{release_draft.genre}"
else
  puts "❌ Failed to update release info:"
  release_draft.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

# Test Step 2 validation logic
puts "\n--- Testing valid_for_step2? logic ---"
def valid_for_step2?(release)
  release.title.present? &&
    release.artist.present? &&
    release.release_date.present?
end

puts "valid_for_step2? result: #{valid_for_step2?(release_draft)}"
puts "Title present: #{release_draft.title.present?}"
puts "Artist present: #{release_draft.artist.present?}"
puts "Release date present: #{release_draft.release_date.present?}"

# Test Step 3: Track requirements
puts "\n--- Step 3: Track requirements ---"
def get_track_requirements(release_type)
  case release_type
  when 'single'
    { min: 1, max: 1, description: '1 track only' }
  when 'ep'
    { min: 2, max: 6, description: '2-6 tracks' }
  when 'album'
    { min: 7, max: nil, description: '7 or more tracks' }
  when 'compilation'
    { min: 2, max: nil, description: '2 or more tracks' }
  end
end

requirements = get_track_requirements(release_draft.release_type)
puts "Track requirements for #{release_draft.release_type}: #{requirements}"

# Test track creation
puts "\n--- Creating test track ---"
track = release_draft.tracks.create!(
  title: "Test Track",
  position: 1,
  duration: 180.0
)
puts "✅ Track created: #{track.title}"

# Test publishing
puts "\n--- Testing publishing ---"
release_draft.status = 'published'
if release_draft.save
  puts "✅ Release published successfully"
else
  puts "❌ Failed to publish release:"
  release_draft.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

puts "\n🎉 Wizard test completed!"

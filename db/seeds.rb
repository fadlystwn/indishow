# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample users and profiles for development
if Rails.env.development?
  puts "Creating sample data..."

  # Create a sample fan user
  fan_user = User.find_or_create_by(email: 'fan@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.role = 'fan'
  end

  # Create fan profile if it doesn't exist
  unless fan_user.fan_profile
    fan_profile = fan_user.create_profile(
      type: 'FanProfile',
      name: 'Music Lover',
      bio: 'Passionate about discovering new indie artists and supporting the underground music scene. Love everything from experimental electronic to raw garage rock.',
      location: 'Portland, OR',
      website_url: 'https://musiclover.blog',
      favorite_genres: 'indie rock, electronic, jazz, ambient'
    )
    puts "Created fan profile: #{fan_profile.name}"
  end

  # Create a sample artist user
  artist_user = User.find_or_create_by(email: 'artist@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.role = 'artist'
  end

  # Create artist profile if it doesn't exist
  unless artist_user.artist_profile
    artist_profile = artist_user.create_profile(
      type: 'ArtistProfile',
      name: 'The Midnight Sound',
      bio: 'Indie rock band from Seattle creating atmospheric soundscapes that blend dreamy vocals with driving rhythms.',
      location: 'Seattle, WA',
      website_url: 'https://midnightsound.com'
    )
    puts "Created artist profile: #{artist_profile.name}"
  end

  puts "Sample data created successfully!"
end

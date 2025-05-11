# app/models/fan_profile.rb
class FanProfile < Profile
  # Fan-specific validations
  validates :favorite_genres, presence: true
end
# app/models/fan_profile.rb
class FanProfile < Profile
  # Fan-specific validations
 validate :genres_format

  private
  def genres_format
    return if favorite_genres.blank?
    # Simple validation - adjust as needed
    errors.add(:favorite_genres, "should be comma-separated") unless favorite_genres.match?(/^[a-zA-Z,\s]+$/)
  end
end
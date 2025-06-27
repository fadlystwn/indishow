# app/models/fan_profile.rb
class FanProfile < Profile
  before_validation :generate_slug, if: -> { slug.blank? }

  validates :slug, presence: true, uniqueness: true
  # Fan-specific validations
  validate :genres_format

  def to_param
    slug
  end

  private

  def generate_slug
    return if name.blank?
    
    self.slug = name.parameterize
    counter = 1
    while FanProfile.exists?(slug: slug) && (slug != name.parameterize + "-#{counter}")
      counter += 1
      self.slug = "#{name.parameterize}-#{counter}"
    end
  end

  def genres_format
    return if favorite_genres.blank?
    # Simple validation - adjust as needed
    errors.add(:favorite_genres, "should be comma-separated") unless favorite_genres.match?(/^[a-zA-Z,\s]+$/)
  end
end
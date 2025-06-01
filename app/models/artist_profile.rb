class ArtistProfile < Profile
  before_validation :generate_slug, if: -> { slug.blank? }

  validates :slug, presence: true, uniqueness: true
  validates :bio, length: { maximum: 1000 }
  validates :location, length: { maximum: 100 }
  validates :website_url, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    message: "must be a valid URL",
    allow_blank: true
  }

  has_one_attached :avatar
  has_one_attached :cover_image

  def to_param
    slug
  end

  private

  def generate_slug
    return if name.blank?
    
    self.slug = name.parameterize
    counter = 1
    while ArtistProfile.exists?(slug: slug) && (slug != name.parameterize + "-#{counter}")
      counter += 1
      self.slug = "#{name.parameterize}-#{counter}"
    end
  end
end
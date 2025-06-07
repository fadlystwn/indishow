class Release < ApplicationRecord
  belongs_to :user
  has_many :tracks, dependent: :destroy

  enum :release_type, [:single, :ep, :album, :compilation]
  enum :status, { draft: 0, published: 1 }
  
  GENRES = [
    'Rock', 'Pop', 'Hip Hop', 'Electronic', 'Classical', 'Jazz',
    'Blues', 'Country', 'R&B', 'Reggae', 'Folk', 'Punk', 'Metal',
    'Indie', 'Alternative', 'World', 'Latin', 'Gospel', 'Funk', 'Soul'
  ].freeze

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  # Conditional validations - only validate for published releases
  validates :title, :release_type, :artist, :release_date, presence: true, if: :published?
  validates :genre, inclusion: { in: GENRES }, allow_blank: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :slug, presence: true, uniqueness: { scope: :user_id }, if: :published?

  # Track count validations based on release type
  validate :validate_track_count, if: :published?

  # Active Storage for cover art with variant processing
  has_one_attached :cover_art do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 300, 300 ]
    attachable.variant :medium, resize_to_limit: [ 600, 600 ]
  end

  def release_type_human
    release_type.titleize
  end

  def to_param
    slug
  end

  private

  def generate_slug
    return if title.blank?
    
    base_slug = title.parameterize
    self.slug = base_slug
    counter = 1
    
    # Use Release.where to avoid issues with user association during creation
    scope = Release.where(user_id: user_id).where.not(id: id || 0)
    while scope.exists?(slug: slug)
      counter += 1
      self.slug = "#{base_slug}-#{counter}"
    end
  end

  def validate_track_count
    return unless release_type.present?
    
    track_count = tracks.count
    
    case release_type
    when 'single'
      errors.add(:tracks, 'Single must have exactly 1 track') unless track_count == 1
    when 'ep'
      errors.add(:tracks, 'EP must have between 2 and 6 tracks') unless track_count.between?(2, 6)
    when 'album'
      errors.add(:tracks, 'Album must have 7 or more tracks') unless track_count >= 7
    when 'compilation'
      errors.add(:tracks, 'Compilation must have 2 or more tracks') unless track_count >= 2
    end
  end
end

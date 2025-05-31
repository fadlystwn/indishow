class Release < ApplicationRecord
  belongs_to :user
  has_many :tracks, dependent: :destroy

  enum release_type: { single: 0, ep: 1, album: 2, compilation: 3 }

  validates :title, :release_type, :artist, :release_date, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  # Active Storage for cover art with variant processing
  has_one_attached :cover_art do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 300, 300 ]
    attachable.variant :medium, resize_to_limit: [ 600, 600 ]
  end

  def release_type_human
    release_type.titleize
  end
end

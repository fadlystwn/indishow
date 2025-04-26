class Release < ApplicationRecord
  belongs_to :user

  enum release_type: { single: 0, ep: 1, album: 2, compilation: 3 }

  validates :title, presence: true
  validates :release_type, presence: true

  def release_type_human
    release_type.titleize
  end
end

class Track < ApplicationRecord
  belongs_to :release

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present?
    self.position = (release.tracks.maximum(:position) || 0) + 1
  end
end

class Track < ApplicationRecord
  include ActiveStorageSlugKey
  belongs_to :release

  has_one_attached :audio_file, service: :skenaria-audio do |attachable|
    attachable.variant :medium, resize_to_limit: [ nil, nil ]
  end

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :audio_file_format, if: -> { audio_file.attached? }

  before_validation :set_position, on: :create

  # Check if track can be streamed
  def streamable?
    audio_file.attached?
  end

  # Duration in seconds for display
  def duration_seconds
    duration
  end

  # Display name with featured artist if present
  def display_title
    if featured_artist.present?
      "#{title} (feat. #{featured_artist})"
    else
      title
    end
  end

  private

  def set_position
    return if position.present?
    self.position = (release.tracks.maximum(:position) || 0) + 1
  end

  def audio_file_format
    return unless audio_file.attached?

    acceptable_types = [ "audio/wav", "audio/flac", "audio/aiff", "audio/alac", "audio/mp3", "audio/mpeg", "audio/aac", "audio/mp4", "audio/m4a" ]
    unless acceptable_types.include?(audio_file.content_type)
      errors.add(:audio_file, "must be an audio file (WAV, FLAC, AIFF, ALAC, MP3, AAC)")
    end

    if audio_file.byte_size > 100.megabytes
      errors.add(:audio_file, "must be less than 100MB")
    end
  end
end

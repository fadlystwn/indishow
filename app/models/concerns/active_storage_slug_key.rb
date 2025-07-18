# frozen_string_literal: true

module ActiveStorageSlugKey
  extend ActiveSupport::Concern

  included do
    after_create_commit :set_custom_blob_key, if: :should_set_custom_key?
  end

  private

  def set_custom_blob_key
    attachment = self
    record = attachment.record
    name = attachment.name
    blob = attachment.blob

    # Only override for audio_file or cover_art
    return unless %w[audio_file cover_art].include?(name)

    # Get artist slug
    artist_slug =
      if record.is_a?(Track)
        record.release.user.artist_profile&.slug || "unknown-artist"
      elsif record.is_a?(Release)
        record.user.artist_profile&.slug || "unknown-artist"
      else
        "unknown-artist"
      end

    # Get song/release title slug
    title_slug =
      if record.is_a?(Track)
        record.title.to_s.parameterize.presence || "untitled"
      elsif record.is_a?(Release)
        record.title.to_s.parameterize.presence || "untitled-release"
      else
        "untitled"
      end

    # Build key
    key =
      if name == "audio_file"
        "#{artist_slug}/#{title_slug}/#{blob.filename.to_s}"
      elsif name == "cover_art"
        "#{artist_slug}/#{title_slug}/cover/#{blob.filename.to_s}"
      end

    blob.update_column(:key, key)
  end

  def should_set_custom_key?
    respond_to?(:record) && respond_to?(:name) && respond_to?(:blob) && blob&.persisted?
  end
end 
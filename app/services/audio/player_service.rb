# frozen_string_literal: true

module Audio
  class PlayerService
    class << self      # Generate a short-lived signed URL for streaming audio
      def stream_url_for(track, user = nil)
        return nil unless track&.audio_file&.attached?

        # Check authorization
        unless authorized_to_stream?(track, user)
          raise UnauthorizedError, "Not authorized to stream this track"
        end

        # Generate signed URL with 1 hour expiration
        # Use Rails.application.routes.url_helpers to get proper URL generation
        url_options = Rails.application.config.action_mailer.default_url_options || { host: "localhost:3000" }
        Rails.application.routes.url_helpers.rails_blob_url(
          track.audio_file,
          expires_in: 1.hour,
          **url_options
        )
      end

      # Check if user is authorized to stream a track
      def authorized_to_stream?(track, user)
        return false unless track&.release

        release = track.release

        # Allow if release is published
        return true if release.published?

        # Allow if user owns the release (for preview during creation)
        return true if user && release.user == user

        # Otherwise, deny access
        false
      end

      # Prepare track data for the audio player
      def track_data_for_player(track, user = nil)
        return nil unless authorized_to_stream?(track, user)

        {
          id: track.id,
          title: track.title,
          artist: track.release.artist,
          duration: track.duration,
          position: track.position,
          stream_url: stream_url_for(track, user),
          cover_art_url: track.release.cover_art.attached? ?
            Rails.application.routes.url_helpers.rails_blob_path(track.release.cover_art.variant(:thumb), only_path: true) :
            nil
        }
      rescue UnauthorizedError
        nil
      end

      # Prepare all tracks from a release for the player queue
      def queue_data_for_release(release, user = nil)
        release.tracks.order(:position).filter_map do |track|
          track_data_for_player(track, user)
        end
      end

      # Save player state to cache
      def save_player_state(user_id, track_id, position, volume = 1.0)
        return unless user_id

        Rails.cache.write(
          player_state_cache_key(user_id),
          {
            track_id: track_id,
            position: position,
            volume: volume,
            updated_at: Time.current
          },
          expires_in: 24.hours
        )
      end

      # Load player state from cache
      def load_player_state(user_id)
        return {} unless user_id

        Rails.cache.read(player_state_cache_key(user_id)) || {}
      end

      private

      def player_state_cache_key(user_id)
        "audio_player_state:#{user_id}"
      end
    end

    class UnauthorizedError < StandardError; end
  end
end

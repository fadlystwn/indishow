class TrackService
  def initialize(user)
    @user = user
  end

  # ──────────────────────────────────────────────────────────────
  # TRACK CREATION BUSINESS LOGIC
  # ──────────────────────────────────────────────────────────────

  def get_next_track_number(release)
    (release.tracks.maximum(:position) || 0) + 1
  end

  def build_tracks_from_params(release, tracks_params)
    tracks_params.map do |track_data|
      release.tracks.build(
        title: track_data[:title],
        duration: track_data[:duration],
        position: track_data[:position]
      )
    end
  end

  def create_multiple_tracks(release, tracks_params)
    tracks = build_tracks_from_params(release, tracks_params)
    errors = []

    Track.transaction do
      tracks.each do |track|
        unless track.save
          errors.concat(track.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end
    end

    if errors.empty?
      { success: true, count: tracks.size, message: "#{tracks.size} #{'track'.pluralize(tracks.size)} successfully created." }
    else
      { success: false, errors: errors, tracks: tracks }
    end
  end

  def create_single_track(release, track_params)
    track = release.tracks.build(track_params)

    if track.save
      { success: true, track: track, message: "Track was successfully created." }
    else
      { success: false, track: track, errors: track.errors.full_messages }
    end
  end

  def update_track(track, track_params)
    if track.update(track_params)
      { success: true, track: track, message: "Track was successfully updated." }
    else
      { success: false, track: track, errors: track.errors.full_messages }
    end
  end

  def delete_track(track)
    track_title = track.title
    track.destroy
    { success: true, message: "Track \"#{track_title}\" was successfully deleted." }
  end

  # ──────────────────────────────────────────────────────────────
  # STREAMING BUSINESS LOGIC
  # ──────────────────────────────────────────────────────────────

  def generate_stream_response(track, current_user)
    unless track.streamable?
      return {
        success: false,
        error: "Track has no audio file",
        status: :not_found,
        log_message: "🎵 Track #{track.id} has no audio file attached"
      }
    end

    begin
      stream_url = Audio::PlayerService.stream_url_for(track, current_user)

      unless stream_url
        return {
          success: false,
          error: "Stream URL not available",
          status: :not_found,
          log_message: "🎵 Failed to generate stream URL for track #{track.id}"
        }
      end

      {
        success: true,
        stream_url: stream_url,
        log_message: "🎵 Generated stream URL for track #{track.id}"
      }
    rescue Audio::PlayerService::UnauthorizedError
      {
        success: false,
        error: "Unauthorized",
        status: :forbidden,
        log_message: "🎵 Unauthorized stream attempt for track #{track.id} by user #{current_user&.id || 'anonymous'}"
      }
    rescue => e
      {
        success: false,
        error: "Track not available",
        status: :not_found,
        log_message: "🎵 Stream error for track #{track&.id}: #{e.message}",
        backtrace: e.backtrace
      }
    end
  end

  # ──────────────────────────────────────────────────────────────
  # AUTHORIZATION HELPERS
  # ──────────────────────────────────────────────────────────────

  def can_manage_tracks?
    @user&.artist?
  end

  def can_manage_release?(release)
    release.user == @user
  end
end

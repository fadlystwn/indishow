class TracksController < ApplicationController
  before_action :authenticate_user!,              except: [ :stream ]
  before_action :authorize_artist_user!,          except: [ :stream ]
  before_action :set_release,                     except: [ :stream ]
  before_action :set_release_and_track,           only: [ :stream ]
  before_action :authorize_release_owner!,        only: [ :edit, :update, :destroy ]
  before_action :set_track,                       only: [ :edit, :update, :destroy ]

  def new
    @track = @release.tracks.build
    set_next_track_number
  end

  def create
    if params[:tracks].present?
      create_multiple_tracks
    else
      create_single_track
    end
  end

  def edit
  end

  def update
    if @track.update(track_params)
      redirect_to @release, notice: "Track was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    track_title = @track.title
    @track.destroy
    redirect_to @release, success: "Track \"#{track_title}\" was successfully deleted."
  end

  def stream
    begin
      log_stream_request

      unless @track.streamable?
        handle_no_audio_file
        return
      end

      stream_url = Audio::PlayerService.stream_url_for(@track, current_user)

      unless stream_url
        handle_no_stream_url
        return
      end

      log_success
      render_stream_response(stream_url)
    rescue Audio::PlayerService::UnauthorizedError
      handle_unauthorized_error
    rescue => e
      handle_general_error(e)
    end
  end

  private

  def set_next_track_number
    @next_track_number = (@release.tracks.maximum(:position) || 0) + 1
  end

  def create_multiple_tracks
    tracks = build_tracks_from_params

    Track.transaction do
      tracks.each do |track|
        unless track.save
          @track = track # for showing errors
          raise ActiveRecord::Rollback
        end
      end

      redirect_to @release, notice: "#{tracks.size} #{'track'.pluralize(tracks.size)} successfully created."
    end
  rescue ActiveRecord::Rollback
    set_next_track_number
    render :new, status: :unprocessable_entity
  end

  def create_single_track
    @track = @release.tracks.build(track_params)

    if @track.save
      redirect_to @release, notice: "Track was successfully created."
    else
      set_next_track_number
      render :new, status: :unprocessable_entity
    end
  end

  def build_tracks_from_params
    params[:tracks].map do |track_data|
      @release.tracks.build(
        title: track_data[:title],
        duration: track_data[:duration],
        position: track_data[:position]
      )
    end
  end

  # Stream helper methods
  def log_stream_request
    Rails.logger.info "🎵 Stream request for track #{@track.id} (release #{@release.id}) by user #{current_user&.id || 'anonymous'}"
  end

  def handle_no_audio_file
    Rails.logger.warn "🎵 Track #{@track.id} has no audio file attached"
    render json: { error: "Track has no audio file" }, status: :not_found
  end

  def handle_no_stream_url
    Rails.logger.warn "🎵 Failed to generate stream URL for track #{@track.id}"
    render json: { error: "Stream URL not available" }, status: :not_found
  end

  def log_success
    Rails.logger.info "🎵 Generated stream URL for track #{@track.id}"
  end

  def render_stream_response(stream_url)
    render json: { stream_url: stream_url }
  end

  def handle_unauthorized_error
    Rails.logger.warn "🎵 Unauthorized stream attempt for track #{@track.id} by user #{current_user&.id || 'anonymous'}"
    render json: { error: "Unauthorized" }, status: :forbidden
  end

  def handle_general_error(error)
    Rails.logger.error "🎵 Stream error for track #{@track&.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render json: { error: "Track not available" }, status: :not_found
  end

  def set_release
    @release = Release.find(params[:release_id])
  end

  def set_release_and_track
    set_release
    set_track
  end

  def set_track
    @track = @release.tracks.find(params[:id])
  end

  def track_params
    params.require(:track).permit(:title, :duration, :position)
  end

  def authorize_artist_user!
    unless current_user&.artist?
      flash[:alert] = "Access denied. Only artists can manage tracks."
      redirect_to root_path
    end
  end

  def authorize_release_owner!
    unless @release.user == current_user
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to release_path(@release)
    end
  end
end

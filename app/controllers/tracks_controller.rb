class TracksController < ApplicationController
  before_action :authenticate_user!,              except: [ :stream ]
  before_action :set_service
  before_action :authorize_artist_user!,          except: [ :stream ]
  before_action :set_release,                     except: [ :stream ]
  before_action :set_release_and_track,           only: [ :stream ]
  before_action :authorize_release_owner!,        only: [ :edit, :update, :destroy ]
  before_action :set_track,                       only: [ :edit, :update, :destroy ]

  def new
    @track = @release.tracks.build
    @next_track_number = @service.get_next_track_number(@release)
  end

  def create
    if params[:tracks].present?
      result = @service.create_multiple_tracks(@release, params[:tracks])

      if result[:success]
        redirect_to @release, notice: result[:message]
      else
        @track = result[:tracks].first # for showing errors
        @next_track_number = @service.get_next_track_number(@release)
        render :new, status: :unprocessable_entity
      end
    else
      result = @service.create_single_track(@release, track_params)

      if result[:success]
        redirect_to @release, notice: result[:message]
      else
        @track = result[:track]
        @next_track_number = @service.get_next_track_number(@release)
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    result = @service.update_track(@track, track_params)

    if result[:success]
      redirect_to @release, notice: result[:message]
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = @service.delete_track(@track)
    redirect_to @release, success: result[:message]
  end

  def stream
    Rails.logger.info "🎵 Stream request for track #{@track.id} (release #{@release.id}) by user #{current_user&.id || 'anonymous'}"

    result = @service.generate_stream_response(@track, current_user)

    if result[:success]
      Rails.logger.info result[:log_message]
      render json: { stream_url: result[:stream_url] }
    else
      Rails.logger.warn result[:log_message]
      Rails.logger.error result[:backtrace].join("\n") if result[:backtrace]
      render json: { error: result[:error] }, status: result[:status]
    end
  end

  private

  def set_service
    @service = TrackService.new(current_user)
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
    unless @service.can_manage_tracks?
      flash[:alert] = "Access denied. Only artists can manage tracks."
      redirect_to root_path
    end
  end

  def authorize_release_owner!
    unless @service.can_manage_release?(@release)
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to release_path(@release)
    end
  end
end

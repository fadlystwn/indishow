class TracksController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_artist_user!
  before_action :set_release
  before_action :set_track, only: [:edit, :update, :destroy, :replace_audio]
  before_action :authorize_release_owner!
  before_action :ensure_published_release, only: [:edit, :update, :replace_audio]

  def edit
    @editor_service = PublishedReleaseEditorService.new(current_user)
    @editable_fields = @editor_service.editable_track_fields
    @restricted_fields = @editor_service.restricted_track_fields
  end

  def update
    @editor_service = PublishedReleaseEditorService.new(current_user)
    
    # Validate track changes
    validation_errors = @editor_service.validate_track_changes(@release, { @track.id => track_params })
    
    if validation_errors.any?
      flash.now[:alert] = validation_errors.join(", ")
      render :edit, status: :unprocessable_entity
      return
    end

    # Update the track
    result = @editor_service.update_track(@track, track_params)
    
    if result[:success]
      redirect_to edit_release_path(@release), notice: result[:message]
    else
      flash.now[:alert] = result[:errors].join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def replace_audio
    @editor_service = PublishedReleaseEditorService.new(current_user)
    
    unless params[:audio_file].present?
      flash.now[:alert] = "Please select an audio file to replace the current track."
      render :edit, status: :unprocessable_entity
      return
    end

    result = @editor_service.replace_track_audio(@track, params[:audio_file])
    
    if result[:success]
      redirect_to edit_release_path(@release), notice: result[:message]
    else
      flash.now[:alert] = result[:errors].join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @release.published?
      flash[:alert] = "Cannot delete tracks from published releases. Please contact support if you need to remove this track."
      redirect_to edit_release_path(@release)
    else
      @track.destroy
      redirect_to edit_release_path(@release), notice: "Track was successfully deleted."
    end
  end

  def stream
    if @track.streamable?
      # Stream the audio file
      redirect_to rails_blob_path(@track.audio_file, disposition: :inline)
    else
      render plain: "Track not available for streaming", status: :not_found
    end
  end

  private

  def set_release
    @release = current_user.releases.find(params[:release_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Release not found."
  end

  def set_track
    @track = @release.tracks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_release_path(@release), alert: "Track not found."
  end

  def authorize_release_owner!
    unless @release.user == current_user
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to release_path(@release)
    end
  end

  def authorize_artist_user!
    unless current_user&.artist?
      flash[:alert] = "Access denied. Only artists can manage tracks."
      redirect_to root_path
    end
  end

  def ensure_published_release
    unless @release.published?
      flash[:alert] = "This action is only available for published releases."
      redirect_to edit_release_path(@release)
    end
  end

  def track_params
    params.require(:track).permit(:title, :featured_artist)
  end
end

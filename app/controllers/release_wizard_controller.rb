class ReleaseWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_service
  before_action :authorize_artist_user!
  before_action :set_release, except: [ :step1, :create_release, :success ]
  before_action :set_release_for_success, only: [ :success ]

  def step1
    # Step 1: Release Type Selection - Entry point
  end

  def create_release
    Rails.logger.info "🎵 [RELEASE_WIZARD] Creating new release for user #{current_user.id} with type: #{params[:release_type]}"

    @release = @service.create_release(params[:release_type])

    if @release.persisted?
      session[:release_id] = @release.id
      Rails.logger.info "✅ [RELEASE_WIZARD] Created release #{@release.id} for user #{current_user.id}"
      redirect_to step2_release_wizard_path(@release.id)
    else
      Rails.logger.error "❌ [RELEASE_WIZARD] Failed to create release for user #{current_user.id}: #{@release.errors.full_messages.join(', ')}"
      redirect_to step1_release_wizard_index_path, alert: "Error creating release"
    end
  end

  def step2
    Rails.logger.info "📝 [RELEASE_WIZARD] User #{current_user.id} accessing step 2 for release #{@release.id}"

    # Step 2: Release Info Form
    return redirect_to step1_release_wizard_index_path unless @release.release_type.present?

    # Auto-fill artist name from user profile if available
    @service.auto_fill_artist_name(@release)
  end

  def step3
    Rails.logger.info "🎶 [RELEASE_WIZARD] User #{current_user.id} accessing step 3 (track upload) for release #{@release.id}"

    # Step 3: Upload Tracks
    return redirect_to step1_release_wizard_index_path unless @release.release_type.present?
    return redirect_to step2_release_wizard_path(@release.id) unless @service.valid_for_step2?(@release)

    @track_requirements = @service.get_track_requirements(@release.release_type)
    @tracks = @release.tracks.order(:position)

    Rails.logger.info "📊 [TRACK_REQ] Release #{@release.id} requires #{@track_requirements[:min]}-#{@track_requirements[:max] || '∞'} tracks, currently has #{@tracks.count}"
  end

  def update_step
    case params[:step]
    when "1"
      update_step1
    when "2"
      update_step2
    when "3"
      update_step3
    else
      redirect_to step1_release_wizard_index_path
    end
  end

  def show
    # Final review - redirect to success page since release is already published
    return redirect_to step1_release_wizard_index_path unless @release.release_type.present?
    return redirect_to step2_release_wizard_path(@release.id) unless @service.valid_for_step2?(@release)
    return redirect_to step3_release_wizard_path(@release.id) unless @release.tracks.any?

    # Clear session and redirect to success
    # Clear session and redirect to success
    session.delete(:release_id)
    redirect_to success_release_wizard_path(@release.id), notice: "Release created successfully!"
  end

  def success
    # Success page - @release is already set by set_release_for_success
    Rails.logger.info "🎉 [RELEASE_WIZARD] Showing success page for release #{@release.id}"
  end

  def debug
    @release = Release.find(params[:id])

    # Security check
    unless @release.user == current_user
      redirect_to root_path, alert: "Access denied"
      return
    end

    @validation_errors = @service.validate_release_for_publishing(@release)
    @track_requirements = @service.get_track_requirements(@release_draft.release_type)
    @tracks = @release_draft.tracks.order(:position)

    # Log detailed debug information
    Rails.logger.info "🔍 [DEBUG] Release #{@release_draft.id} Status:"
    Rails.logger.info "  - Type: #{@release_draft.release_type}"
    Rails.logger.info "  - Status: #{@release_draft.status}"
    Rails.logger.info "  - Track count: #{@tracks.count}"
    Rails.logger.info "  - Cover art? #{@release_draft.cover_art.attached?}"
    Rails.logger.info "  - Validation errors: #{@validation_errors.join(', ')}"

    render :debug
  end

  private

  def set_service
    @service = ReleaseWizardService.new(current_user)
  end

  def set_release
    # Find release from session
    release_id = session[:release_id]
    @release = current_user.releases.find(release_id) if release_id

    # Redirect to step1 if no release found
    unless @release
      redirect_to step1_release_wizard_index_path
      nil
    end
  end

  def update_step1
    if @release.update(release_type: params[:release_type])
      redirect_to step2_release_wizard_path(@release.id)
    else
      redirect_to step1_release_wizard_index_path, alert: @release.errors.full_messages.join(", ")
    end
  end

  def update_step2
    Rails.logger.info "📝 [RELEASE_UPDATE] Updating step 2 data for release #{@release.id}: #{step2_params}"

    if @service.update_step2(@release, step2_params)
      redirect_to step3_release_wizard_path(@release.id)
    else
      render :step2, status: :unprocessable_entity
    end
  end

  def update_step3
    # Permit track parameters properly
    permitted_tracks = params[:tracks]&.permit! if params[:tracks].present?

    track_errors = @service.update_step3(@release, permitted_tracks, params[:audio_files])

    if track_errors.empty?
      redirect_to release_wizard_path(@release.id)
    else
      flash.now[:alert] = track_errors.join(", ")
      @track_requirements = @service.get_track_requirements(@release.release_type)
      @tracks = @release.tracks.order(:position)
      render :step3, status: :unprocessable_entity
    end
  end

  def step2_params
    params.require(:release).permit(:title, :artist, :release_date, :price, :description, :genre, :cover_art, :release_type)
  end

  def track_params
    if params[:tracks].present?
      params.require(:tracks).permit!
    else
      {}
    end
  end

  def set_release_for_success
    @release = Release.find(params[:id])

    # Ensure the release belongs to the current user
    unless @release.user == current_user
      redirect_to root_path, alert: "Access denied."
      nil
    end
  end

  def authorize_artist_user!
    unless current_user&.artist?
      flash[:alert] = "Access denied. Only artists can create releases."
      redirect_to root_path
    end
  end
end

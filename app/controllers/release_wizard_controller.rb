class ReleaseWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_service
  before_action :authorize_artist_user!
  before_action :set_release_draft, except: [ :step1, :create_draft, :success ]
  before_action :set_published_release, only: [ :success ]

  def step1
    # Step 1: Release Type Selection - Entry point
    draft_id = session[:release_draft_id]
    @release_draft = @service.find_or_create_draft(draft_id)
  end

  def create_draft
    Rails.logger.info "🎵 [RELEASE_WIZARD] Creating new release draft for user #{current_user.id} with type: #{params[:release_type]}"

    @release_draft = @service.create_initial_draft(params[:release_type])

    if @release_draft.persisted?
      session[:release_draft_id] = @release_draft.id
      Rails.logger.info "✅ [RELEASE_WIZARD] Created draft release #{@release_draft.id} for user #{current_user.id}"
      redirect_to step2_release_wizard_path(@release_draft.id)
    else
      Rails.logger.error "❌ [RELEASE_WIZARD] Failed to create draft release for user #{current_user.id}: #{@release_draft.errors.full_messages.join(', ')}"
      redirect_to step1_release_wizard_index_path, alert: "Error creating draft release"
    end
  end

  def step2
    Rails.logger.info "📝 [RELEASE_WIZARD] User #{current_user.id} accessing step 2 for release draft #{@release_draft.id}"

    # Step 2: Release Info Form
    return redirect_to step1_release_wizard_index_path unless @release_draft.release_type.present?

    # Auto-fill artist name from user profile if available
    @service.auto_fill_artist_name(@release_draft)
  end

  def step3
    Rails.logger.info "🎶 [RELEASE_WIZARD] User #{current_user.id} accessing step 3 (track upload) for release draft #{@release_draft.id}"

    # Step 3: Upload Tracks
    return redirect_to step1_release_wizard_index_path unless @release_draft.release_type.present?
    return redirect_to step2_release_wizard_path(@release_draft.id) unless @service.valid_for_step2?(@release_draft)

    @track_requirements = @service.get_track_requirements(@release_draft.release_type)
    @tracks = @release_draft.tracks.order(:position)

    Rails.logger.info "📊 [TRACK_REQ] Release #{@release_draft.id} requires #{@track_requirements[:min]}-#{@track_requirements[:max] || '∞'} tracks, currently has #{@tracks.count}"
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
    # Final review before publishing
    return redirect_to step1_release_wizard_index_path unless @release_draft.release_type.present?
    return redirect_to step2_release_wizard_path(@release_draft.id) unless @service.valid_for_step2?(@release_draft)
    return redirect_to step3_release_wizard_path(@release_draft.id) unless @release_draft.tracks.any?

    # Temporarily set status to published to validate
    @release_draft.status = "published"
    @release_draft.valid? # This will populate errors
    @release_draft.status = "draft" # Reset back to draft
  end

  def create
    # Publish the release
    if @service.publish_release(@release_draft)
      session.delete(:release_draft_id)
      redirect_to success_release_wizard_path(@release_draft.id), notice: "Release was successfully created and published!"
    else
      @release_draft.status = "draft" # Reset back to draft on error
      redirect_to release_wizard_path(@release_draft.id), alert: "There was an error publishing your release. Please fix the issues and try again."
    end
  end

  def success
    # Success page after publishing - @release is already set by set_published_release
  end

  private

  def set_service
    @service = ReleaseWizardService.new(current_user)
  end

  def set_release_draft
    # Find or create draft release for current session
    draft_id = session[:release_draft_id]
    @release_draft = @service.find_or_create_draft(draft_id)
    session[:release_draft_id] = @release_draft.id
  end

  def update_step1
    if @release_draft.update(release_type: params[:release_type])
      redirect_to step2_release_wizard_path(@release_draft.id)
    else
      render :step1, status: :unprocessable_entity
    end
  end

  def update_step2
    Rails.logger.info "📝 [RELEASE_UPDATE] Updating step 2 data for release #{@release_draft.id}: #{step2_params.except(:cover_art).to_h}"

    if @service.update_step2(@release_draft, step2_params)
      Rails.logger.info "✅ [RELEASE_UPDATE] Successfully updated release #{@release_draft.id} step 2 data"
      redirect_to step3_release_wizard_path(@release_draft.id)
    else
      Rails.logger.warn "❌ [RELEASE_UPDATE] Failed to update release #{@release_draft.id}: #{@release_draft.errors.full_messages.join(', ')}"
      render :step2, status: :unprocessable_entity
    end
  end

  def update_step3
    track_errors = @service.update_step3(@release_draft, track_params, params[:audio_files])

    if track_errors.empty?
      redirect_to release_wizard_path(@release_draft.id)
    else
      flash.now[:alert] = track_errors.join(" ")
      @track_requirements = @service.get_track_requirements(@release_draft.release_type)
      @tracks = @release_draft.tracks.order(:position)
      render :step3, status: :unprocessable_entity
    end
  end

  def step2_params
    params.require(:release).permit(:title, :artist, :release_date, :price, :description, :genre, :cover_art, :release_type)
  end

  def track_params
    if params[:tracks].present?
      params.require(:tracks).permit!.to_h
    else
      {}
    end
  end

  def set_published_release
    @release = Release.find(params[:id])

    # Ensure the release belongs to the current user
    unless @release.user == current_user
      redirect_to root_path, alert: "Access denied."
      return
    end

    # Ensure the release is published
    unless @release.published?
      redirect_to root_path, alert: "Release not found."
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

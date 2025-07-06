class ReleaseWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_service
  before_action :authorize_artist_user!
  before_action :set_release, except: [ :step1, :create_release, :success ]
  before_action :set_release_for_success, only: [ :success ]
  before_action :set_edit_release, only: [ :edit_step2, :edit_step3 ]

  def step1
    # Entry: choose release type
  end

  def create_release
    # Reuse existing release in session if it exists and belongs to current_user
    if session[:release_id] && current_user.releases.exists?(id: session[:release_id])
      @release = current_user.releases.find(session[:release_id])
      @release.update(release_type: params[:release_type]) if params[:release_type].present?
      redirect_to step2_release_wizard_path(@release.id)
      return
    end

    # Otherwise create a new release
    @release = @service.create_release(params[:release_type])

    if @release.persisted?
      session[:release_id] = @release.id
      redirect_to step2_release_wizard_path(@release.id)
    else
      redirect_to step1_release_wizard_index_path, alert: "Error creating release"
    end
  end


  def step2
    @service.auto_fill_artist_name(@release)
    @edit_mode = false
  end

  def edit_step2
    @service.auto_fill_artist_name(@release)
    @edit_mode = true
    render :step2
  end

  def step3
    return redirect_to step2_release_wizard_path(@release.id) unless @service.valid_for_step2?(@release)

    @track_requirements = @service.get_track_requirements(@release.release_type)
    @tracks = @release.tracks.order(:position)
    @edit_mode = false

    Rails.logger.info "📊 Track requirement: #{@track_requirements[:min]}-#{@track_requirements[:max] || '∞'} (have #{@tracks.count})"
  end

  def edit_step3
    return redirect_to edit_step2_release_wizard_path(@release.id) unless @service.valid_for_step2?(@release)

    @track_requirements = @service.get_track_requirements(@release.release_type)
    @tracks = @release.tracks.order(:position)
    @edit_mode = true

    Rails.logger.info "📊 Track requirement: #{@track_requirements[:min]}-#{@track_requirements[:max] || '∞'} (have #{@tracks.count})"
    render :step3
  end

  def update_step
    case params[:step]
    when "1" then update_step1
    when "2" then update_step2
    when "3" then update_step3
    else redirect_to step1_release_wizard_index_path
    end
  end

  def show
    return redirect_to step2_release_wizard_path(@release.id) unless @service.valid_for_step2?(@release)
    return redirect_to step3_release_wizard_path(@release.id) unless @release.tracks.any?

    session.delete(:release_id)
    redirect_to success_release_wizard_path(@release.id), notice: "Release created successfully!"
  end

  def success
    Rails.logger.info "🎉 Showing success page for release #{@release.id}"
  end

  def debug
    @release = Release.find(params[:id])
    return redirect_to root_path, alert: "Access denied" unless @release.user == current_user

    @validation_errors = @service.validate_release_for_publishing(@release)
    @track_requirements = @service.get_track_requirements(@release.release_type)
    @tracks = @release.tracks.order(:position)

    Rails.logger.info "🔍 Debug Release #{@release.id}: #{@validation_errors.join(', ')}"
    render :debug
  end


  private

  def set_service
    @service = ReleaseWizardService.new(current_user)
  end

  def set_release
    @release = current_user.releases.find_by(id: session[:release_id])
    redirect_to step1_release_wizard_index_path unless @release
  end

  def set_edit_release
    @release = current_user.releases.find(params[:id])
    redirect_to root_path, alert: "Access denied." unless @release.user == current_user
  end

  def set_release_for_success
    @release = Release.find(params[:id])
    redirect_to root_path, alert: "Access denied." unless @release.user == current_user
  end

  def update_step1
    if @release.update(release_type: params[:release_type])
      redirect_to step2_release_wizard_path(@release.id)
    else
      redirect_to step1_release_wizard_index_path, alert: @release.errors.full_messages.join(", ")
    end
  end

  def update_step2
    Rails.logger.info "📝 Updating step 2 for release #{@release.id}: #{step2_params}"

    if @service.update_step2(@release, step2_params)
      # Check if we're in edit mode by looking at the referer or a parameter
      if params[:edit_mode] == "true" || request.referer&.include?("edit_step2")
        redirect_to edit_step3_release_wizard_path(@release.id)
      else
        redirect_to step3_release_wizard_path(@release.id)
      end
    else
      @edit_mode = params[:edit_mode] == "true" || request.referer&.include?("edit_step2")
      render :step2, status: :unprocessable_entity
    end
  end

  def update_step3
    permitted_tracks = params[:tracks]&.permit! if params[:tracks].present?
    track_errors = @service.update_step3(@release, permitted_tracks, params[:audio_files])

    if track_errors.empty?
      # Check if we're in edit mode
      if params[:edit_mode] == "true" || request.referer&.include?("edit_step3")
        redirect_to release_path(@release), notice: "Release was successfully updated."
      else
        redirect_to release_wizard_path(@release.id)
      end
    else
      flash.now[:alert] = track_errors.join(", ")
      @track_requirements = @service.get_track_requirements(@release.release_type)
      @tracks = @release.tracks.order(:position)
      @edit_mode = params[:edit_mode] == "true" || request.referer&.include?("edit_step3")
      render :step3, status: :unprocessable_entity
    end
  end

  def step2_params
    params.require(:release).permit(:title, :artist, :release_date, :price, :description, :genre, :cover_art)
  end

  def authorize_artist_user!
    unless current_user&.artist?
      redirect_to root_path, alert: "Access denied. Only artists can create releases."
    end
  end
end

class ReleasesController < ApplicationController
  before_action :authenticate_user!,              except: [ :show ]
  before_action :authorize_artist_user!,          except: [ :show ]
  before_action :set_release,                     only: [ :show, :edit, :update, :destroy, :publish ]
  before_action :authorize_release_owner!,        only: [ :edit, :update, :destroy, :publish ]
  before_action :prevent_modifying_published_release!, only: [ :destroy ]

  def index
    @releases = current_user.releases.order(release_date: :desc)
  end

  def show; end

  def edit
    if @release.published?
      # Use the new published release editor service
      @editor_service = PublishedReleaseEditorService.new(current_user)
      
      unless @editor_service.can_edit_release?(@release)
        redirect_to release_path(@release), alert: "You can only edit your own published releases."
        return
      end
      
      # Set up the edit form for published releases
      @editable_fields = @editor_service.editable_release_fields
      @restricted_fields = @editor_service.restricted_release_fields
      @editable_track_fields = @editor_service.editable_track_fields
      @restricted_track_fields = @editor_service.restricted_track_fields
      
      # Render the published release edit view
      render :edit_published
    else
      # Redirect to the multi-step wizard edit flow for drafts
      redirect_to edit_step2_release_wizard_path(@release.id)
    end
  end

  def update
    if @release.published?
      update_published_release
    else
      update_draft_release
    end
  end

  def destroy
    title = @release.title
    @release.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Release \"#{title}\" was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Release \"#{title}\" was successfully deleted." }
    end
  end

  def publish
    service = ReleaseWizardService.new(current_user)
    errors  = service.validate_release_for_publishing(@release)

    if errors.empty?
      @release.update!(status: "published")
      redirect_to dashboard_path, notice: "Release published!"
    else
      redirect_to edit_release_path(@release), alert: errors.join(", ")
    end
  end

  private

  def update_published_release
    @editor_service = PublishedReleaseEditorService.new(current_user)
    
    # Validate the changes
    validation_errors = @editor_service.validate_release_changes(@release, release_params)
    
    if validation_errors.any?
      flash.now[:alert] = validation_errors.join(", ")
      render :edit, status: :unprocessable_entity
      return
    end

    # Update the release
    result = @editor_service.update_release(@release, release_params)
    
    if result[:success]
      redirect_to release_path(@release), notice: result[:message]
    else
      flash.now[:alert] = result[:errors].join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def update_draft_release
    if @release.update(release_params)
      redirect_to dashboard_path, notice: "Release was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def set_release
    numeric = params[:id].match?(/\A\d+\z/)

    if action_name == "show"
      scope = Release.published
      @release = numeric ? scope.find_by(id: params[:id]) : scope.find_by(slug: params[:id])
      if @release.nil? && user_signed_in?
        owner_scope = current_user.releases
        @release = numeric ? owner_scope.find_by(id: params[:id]) : owner_scope.find_by(slug: params[:id])
      end
    else
      scope = Release
      @release = numeric ? scope.find_by(id: params[:id]) : scope.find_by(slug: params[:id])
    end

    raise ActiveRecord::RecordNotFound unless @release
  end

  def authorize_release_owner!
    unless @release.user == current_user
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to release_path(@release)
    end
  end

  def authorize_artist_user!
    unless current_user&.artist?
      flash[:alert] = "Access denied. Only artists can manage releases."
      redirect_to root_path
    end
  end

  def prevent_modifying_published_release!
    if @release.published?
      flash[:alert] = "Published releases cannot be deleted. Please contact support if you need to remove this release."
      redirect_to release_path(@release)
    end
  end

  def release_params
    params.require(:release).permit(
      :title,
      :artist,
      :release_date,
      :price,
      :description,
      :genre,
      :cover_art
    )
  end
end

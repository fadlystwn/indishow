class ReleasesController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :authorize_artist_user!, except: [ :show ]
  before_action :set_release, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_release_owner!, only: [ :edit, :update, :destroy ]
  before_action :prevent_modifying_published_release!, only: [ :edit, :update, :destroy ]

  def index
    @releases = current_user.releases.published.order(release_date: :desc)
  end

  def show
    # Publicly accessible show page
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    Rails.logger.info "📝 Updating release: #{@release.title} (ID: #{@release.id})"

    if @release.update(release_params)
      Rails.logger.info "✅ Release updated successfully: #{@release.title}"
      redirect_to release_path(@release), notice: "Release was successfully updated."
    else
      Rails.logger.warn "❌ Release update failed: #{@release.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @release_title = @release.title
    @release.destroy

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Release \"#{@release_title}\" was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Release \"#{@release_title}\" was successfully deleted." }
    end
  end

  private

  def set_release
    if action_name == "show"
      @release = if params[:id].match?(/\A\d+\z/)
                   Release.published.find(params[:id])
      else
                   Release.published.find_by!(slug: params[:id])
      end
    else
      @release = if params[:id].match?(/\A\d+\z/)
                   Release.find(params[:id])
      else
                   Release.find_by!(slug: params[:id])
      end
    end
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
      flash[:alert] = "This release is already published and cannot be modified."
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

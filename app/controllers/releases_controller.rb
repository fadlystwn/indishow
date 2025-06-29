class ReleasesController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :authorize_artist_user!, except: [ :show ]
  before_action :set_release, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_release_owner!, only: [ :edit, :update, :destroy ]
  before_action :prevent_modifying_published_release!, only: [ :edit, :update, :destroy ]

  def index
    @releases = current_user.releases.order(release_date: :desc)
  end

  def show; end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    if @release.update(release_params)
      redirect_to dashboard_path, notice: "Release was successfully updated."
    else
      render :edit, status: :unprocessable_entity
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

  private

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

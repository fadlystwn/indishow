class ReleasesController < ApplicationController
  before_action :authenticate_user!, except: [:show] # Allow public access to show
  before_action :authorize_artist_user!, except: [:show] # Restrict fan users from all actions except show
  before_action :set_release, only: [:show, :edit, :update, :destroy]
  before_action :authorize_release_owner!, only: [:edit, :update, :destroy]

  def index
    @releases = current_user.releases.published.order(release_date: :desc)
  end

  def show
    # @release is already set by set_release
    # Show page is accessible by everyone (fans can view and buy)
  end

  def new
    @release = current_user.releases.new
  end

  def create
    @release = current_user.releases.new(release_params)

    if @release.save
      redirect_to release_path(@release), notice: "Release was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @release is already set by the before_action :set_release
    respond_to do |format|
      format.html # Renders the edit template
      format.turbo_stream # For Turbo Frame responses
    end
  end

  def update
    if @release.update(release_params)
      redirect_to release_path(@release), notice: "Release was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    release_title = @release.title
    @release.destroy

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Release \"#{release_title}\" was successfully deleted." }
      format.turbo_stream
    end
  end

  private

  def set_release
    @release = if params[:id].match?(/\A\d+\z/)
                 Release.published.find(params[:id])
               else
                 Release.published.find_by!(slug: params[:id])
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
  def release_params
    params.require(:release).permit(
      :title,
      :artist,
      :release_type,
      :release_date,
      :price,
      :description,
      :genre,
      :cover_art
    )
  end
end

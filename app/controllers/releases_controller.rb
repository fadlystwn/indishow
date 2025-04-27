class ReleasesController < ApplicationController
  before_action :authenticate_user! # Requires user to be logged in
  before_action :set_release, only: [ :edit, :update, :destroy ]

  def index
    @releases = current_user.releases.order(release_date: :desc)
  end

  def new
    @release = current_user.releases.new
  end

  def create
    @release = current_user.releases.new(release_params)

    if @release.save
      redirect_to root_path, notice: "Release was successfully created."
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
      redirect_to root_path, notice: "Release was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @release.destroy
    redirect_to root_path, notice: "Release was successfully destroyed."
  end

  private

  def set_release
    @release = current_user.releases.find(params[:id])
  end

  def release_params
    params.require(:release).permit(
      :title,
      :artist,
      :release_type,
      :release_date,
      :price,
      :description,
      :cover_art
    )
  end
end

class ArtistProfilesController < ApplicationController
  before_action :set_artist_profile, only: [:show, :edit, :update]
  before_action :authenticate_user!, except: [:show]

  def show
    @releases = Release.where(user: @artist_profile.user)
                      .order(release_date: :desc)
                      .includes(cover_art_attachment: :blob)
                      .with_attached_cover_art
  end

  def edit
    authorize_profile_owner!
  end

  def update
    authorize_profile_owner!
    
    if @artist_profile.update(artist_profile_params)
      redirect_to artist_profile_path(@artist_profile), notice: 'Profile was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_artist_profile
    @artist_profile = if params[:id].match?(/\A\d+\z/)
                       ArtistProfile.find(params[:id])
                     else
                       ArtistProfile.find_by!(slug: params[:id])
                     end
  end

  def artist_profile_params
    params.require(:artist_profile).permit(:name, :bio, :location, :website_url, :avatar, :cover_image)
  end

  def authorize_profile_owner!
    unless user_signed_in? && @artist_profile.user == current_user
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to artist_profile_path(@artist_profile)
    end
  end
end

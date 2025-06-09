# app/controllers/follows_controller.rb
class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_artist, only: [:create, :destroy]

  def create
    if current_user.fan?
      follow = current_user.follow(@artist.user)
      if follow&.persisted?
        respond_to do |format|
          format.json { render json: { status: 'success', message: 'Successfully followed artist' } }
          format.html { redirect_back(fallback_location: artist_profile_path(@artist), notice: 'Successfully followed artist!') }
        end
      else
        respond_to do |format|
          format.json { render json: { status: 'error', message: 'Failed to follow artist' } }
          format.html { redirect_back(fallback_location: artist_profile_path(@artist), alert: 'Failed to follow artist.') }
        end
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Only fans can follow artists' } }
        format.html { redirect_back(fallback_location: artist_profile_path(@artist), alert: 'Only fans can follow artists.') }
      end
    end
  end

  def destroy
    current_user.unfollow(@artist.user)
    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Successfully unfollowed artist' } }
      format.html { redirect_back(fallback_location: artist_profile_path(@artist), notice: 'Successfully unfollowed artist!') }
    end
  end

  private

  def set_artist
    @artist = if params[:id].match?(/\A\d+\z/)
                ArtistProfile.find(params[:id])
              else
                ArtistProfile.find_by!(slug: params[:id])
              end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: 'error', message: 'Artist not found' } }
      format.html { redirect_to root_path, alert: 'Artist not found.' }
    end
  end
end

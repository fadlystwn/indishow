class FanProfilesController < ApplicationController
  before_action :set_fan_profile, only: [:show, :edit, :update]
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @fan_profiles = FanProfile.includes(:user, avatar_attachment: :blob)
                              .where.not(slug: [nil, ''])
                              .order(created_at: :desc)
                              .page(params[:page]).per(12)
  end

  def show
    # For fans, we can show their favorite genres, activity, reviews, etc.
    # For now, we'll keep it simple
  end

  def edit
    authorize_profile_owner!
  end

  def update
    authorize_profile_owner!
    
    if @fan_profile.update(fan_profile_params)
      redirect_to fan_profile_path(@fan_profile), notice: 'Profile was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_fan_profile
    @fan_profile = if params[:id].match?(/\A\d+\z/)
                     FanProfile.find(params[:id])
                   else
                     FanProfile.find_by!(slug: params[:id])
                   end
  end

  def fan_profile_params
    params.require(:fan_profile).permit(:name, :bio, :location, :website_url, :favorite_genres, :avatar)
  end

  def authorize_profile_owner!
    unless user_signed_in? && @fan_profile.user == current_user
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to fan_profile_path(@fan_profile)
    end
  end
end

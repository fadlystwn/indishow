class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation, :role, profile_attributes: [:name]])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :current_password, profile_attributes: [:name, :bio, :location, :website_url]])
  end

  def build_resource(hash = {})
    super.tap do |user|
      # Build the appropriate profile based on role
      if user.role.present?
        profile_type = user.artist? ? :artist_profile : :fan_profile
        user.build_profile(
          type: "#{profile_type.to_s.camelize}",
          name: hash.dig(:profile_attributes, :name)
        )
      end
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :email, 
      :password, 
      :password_confirmation, 
      :role,
      profile_attributes: [
        :name, 
        :bio, 
        :location, 
        :website_url,
        :favorite_genres
      ]
    )
  end

  def account_update_params
    params.require(:user).permit(
      :email, 
      :password, 
      :password_confirmation, 
      :current_password,
      profile_attributes: [
        :id,
        :name, 
        :bio, 
        :location, 
        :website_url,
        :favorite_genres,
        :avatar,
        :cover_image
      ]
    )
  end
end
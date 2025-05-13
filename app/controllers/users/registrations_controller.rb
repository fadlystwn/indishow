class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :email, :password, :password_confirmation, :role,
      profile_attributes: [:name, :bio, :location, :website_url, :favorite_genres, :type]
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :email, :password, :password_confirmation, :current_password,
      profile_attributes: [:id, :name, :bio, :location, :website_url, :favorite_genres, :avatar, :cover_image]
    ])
  end

  def build_resource(hash = {})
    super(hash)

    return unless hash[:profile_attributes] && resource.role.present?

    profile_type = resource.artist? ? 'ArtistProfile' : 'FanProfile'
    resource.build_profile(hash[:profile_attributes].merge(type: profile_type))
  end

  private

  def sign_up_params
    params = super
    if params[:profile_attributes] && params[:role]
      profile_type = params[:role] == 'artist' ? 'ArtistProfile' : 'FanProfile'
      params[:profile_attributes][:type] = profile_type
    end
    params
  end

  def account_update_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :current_password,
      profile_attributes: [:id, :name, :bio, :location, :website_url, :favorite_genres, :avatar, :cover_image]
    )
  end
end
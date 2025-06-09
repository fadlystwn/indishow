class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters
  before_action :ensure_profile_exists, only: [:edit, :update]

  def create
    Rails.logger.info "👤 [USER_REG] Attempting user registration with role: #{params.dig(:user, :role)}"
    
    super do |resource|
      if resource.persisted?
        Rails.logger.info "✅ [USER_REG] Successfully created user #{resource.id} (#{resource.email}) with role: #{resource.role}"
        Rails.logger.info "📝 [PROFILE] Created #{resource.profile.class.name} profile (ID: #{resource.profile.id}) for user #{resource.id}"
      else
        Rails.logger.warn "❌ [USER_REG] Failed to create user: #{resource.errors.full_messages.join(', ')}"
      end
    end
  end

  def update
    Rails.logger.info "📝 [USER_UPDATE] Updating user #{resource.id} profile"
    
    super do |resource|
      if resource.errors.empty?
        Rails.logger.info "✅ [USER_UPDATE] Successfully updated user #{resource.id} and profile"
      else
        Rails.logger.warn "❌ [USER_UPDATE] Failed to update user #{resource.id}: #{resource.errors.full_messages.join(', ')}"
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :email, :password, :password_confirmation, :role,
      profile_attributes: [:name, :bio, :location, :website_url, :favorite_genres, :type]
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :email, :password, :password_confirmation, :current_password,
      profile_attributes: [:id, :name, :bio, :location, :website_url, :favorite_genres]
    ])
  end

  def build_resource(hash = {})
    super(hash)

    return unless hash[:profile_attributes] && resource.role.present?

    profile_type = resource.artist? ? 'ArtistProfile' : 'FanProfile'
    resource.build_profile(hash[:profile_attributes].merge(type: profile_type))
  end

  private

  def ensure_profile_exists
    return if resource.profile.present?
    
    profile_type = resource.artist? ? 'ArtistProfile' : 'FanProfile'
    resource.create_profile(type: profile_type)
  end

  def sign_up_params
    params = super
    if params[:profile_attributes] && params[:role]
      profile_type = params[:role] == 'artist' ? 'ArtistProfile' : 'FanProfile'
      params[:profile_attributes][:type] = profile_type
    end
    params
  end

  def account_update_params
    permitted_params = params.require(:user).permit(
      :email, :password, :password_confirmation, :current_password,
      profile_attributes: [:id, :name, :bio, :location, :website_url, :favorite_genres]
    )

    permitted_params
  end

  def update_resource(resource, params)
    Rails.logger.info "🔄 [PROFILE_UPDATE] Updating profile for user #{resource.id}"
    
    # First, ensure the profile exists and is saved
    if resource.profile.new_record?
      Rails.logger.info "📝 [PROFILE] Creating new profile record for user #{resource.id}"
      resource.profile.save!
    end

    # Handle avatar separately
    if params[:profile_attributes].present? && params[:profile_attributes][:avatar].present?
      Rails.logger.info "🖼️ [AVATAR] Uploading new avatar for user #{resource.id}"
      resource.profile.avatar.attach(params[:profile_attributes][:avatar])
    end

    # Handle avatar removal
    if params[:remove_avatar] == "1"
      Rails.logger.info "🗑️ [AVATAR] Removing avatar for user #{resource.id}"
      resource.profile.avatar.purge if resource.profile.avatar.attached?
    end

    # Update the profile first if it has changes
    if params[:profile_attributes].present?
      profile_params = params[:profile_attributes].except(:avatar)
      resource.profile.update(profile_params) if profile_params.present?
    end

    # Then update the user
    super
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end

  def after_sign_up_path_for(resource)
    Rails.logger.info "🏠 [REDIRECT] Redirecting newly registered #{resource.role} user #{resource.id} to #{resource.artist? ? 'dashboard' : 'root'}"
    if resource.artist?
      dashboard_path
    else
      root_path
    end
  end
end
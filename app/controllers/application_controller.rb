class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Add flash types for better user feedback
  add_flash_types :success, :error, :warning, :info

  protected

  # Redirect artists to dashboard after sign in
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.artist?
      dashboard_path
    else
      stored_location_for(resource) || root_path
    end
  end
end

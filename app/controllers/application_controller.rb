class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Add flash types for better user feedback
  add_flash_types :success, :error, :warning, :info

  before_action :log_request_start
  after_action :log_request_end

  protected

  # Redirect artists to dashboard after sign in
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.artist?
      Rails.logger.info "🎯 [AUTH] Artist user #{resource.id} (#{resource.email}) signed in, redirecting to dashboard"
      dashboard_path
    else
      Rails.logger.info "🎯 [AUTH] User #{resource.id} (#{resource.email}) signed in, redirecting to root"
      stored_location_for(resource) || root_path
    end
  end

  private

  def log_request_start
    Rails.logger.info "🚀 [REQUEST] #{request.method} #{request.path} - User: #{current_user&.id || 'Guest'} - IP: #{request.remote_ip} - User-Agent: #{request.user_agent&.truncate(100)}"
    @request_start_time = Time.current
  end

  def log_request_end
    duration = Time.current - @request_start_time if @request_start_time
    status_emoji = response.status >= 400 ? "❌" : response.status >= 300 ? "↩️" : "✅"
    Rails.logger.info "#{status_emoji} [RESPONSE] #{request.method} #{request.path} - Status: #{response.status} - Duration: #{duration&.round(3)}s"
  end
end

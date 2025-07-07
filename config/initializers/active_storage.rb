# Configure ActiveStorage for development
Rails.application.configure do
  # Ensure ActiveStorage URLs are generated correctly
  if Rails.env.development?
    # Set default URL options for ActiveStorage routes
    config.after_initialize do
      ActiveStorage::Current.url_options = {
        host: Rails.application.config.action_mailer.default_url_options[:host],
        port: Rails.application.config.action_mailer.default_url_options[:port],
        protocol: "http"
      }
    end
  end
end

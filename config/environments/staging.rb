# config/environments/staging.rb
# Staging environment is meant to mirror production as closely as possible.
# You can override production settings here if needed.

require_relative "production"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb and config/environments/production.rb.

  # Eager load code on boot. This is necessary for staging to mirror production.
  config.eager_load = true

  # Show full error reports (optional, set to false if you want to hide errors in staging)
  config.consider_all_requests_local = true

  # Optionally, do not cache classes in staging for easier debugging
  # config.cache_classes = false

  # Add any other staging-specific overrides below
end 
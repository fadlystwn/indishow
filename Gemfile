source "https://rubygems.org"

# Core Rails gems
gem "rails", "~> 7.2.2", ">= 7.2.2.1"
gem "sprockets-rails"
gem "sqlite3", "~> 1.6.0"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Frontend and assets
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "image_processing", "~> 1.2"
gem "tailwindcss-rails", "~> 3.3.1"

# Background jobs and caching
gem "sidekiq"
gem "redis"

# Authentication
gem "devise"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# UI and pagination
gem "kaminari"
gem "plyr-rails"

# Platform-specific
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

group :development, :test do
  # Debugging and testing
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ], require: "debug/prelude"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "rails-controller-testing"
  gem "dotenv-rails"

  # Code quality
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "error_highlight", ">= 0.4.0", platforms: [ :ruby ]
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

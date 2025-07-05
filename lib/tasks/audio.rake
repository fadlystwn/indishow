namespace :audio do
  desc "Check ActiveStorage configuration for audio streaming"
  task check_config: :environment do
    puts "🎵 Checking ActiveStorage configuration..."
    puts "Default URL options: #{Rails.application.config.action_mailer.default_url_options}"
    puts "ActiveStorage service: #{Rails.application.config.active_storage.service}"
    puts "Current environment: #{Rails.env}"

    if Rails.env.development?
      puts "✅ Development environment detected"
      puts "Rails should be running on: http://localhost:5000"
    end

    puts "🎵 Configuration check complete!"
  end
end

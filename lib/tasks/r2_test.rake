namespace :r2 do
  desc "Test R2 configuration"
  task test: :environment do
    puts "Testing R2 configuration..."
    
    begin
      # Test if we can create a blob
      test_file = Tempfile.new(['test', '.txt'])
      test_file.write("This is a test file for R2 configuration")
      test_file.rewind
      
      blob = ActiveStorage::Blob.create_and_upload!(
        io: test_file,
        filename: "r2_test_#{Time.current.to_i}.txt",
        content_type: "text/plain"
      )
      
      puts "✅ R2 configuration is working!"
      puts "Uploaded file: #{blob.filename}"
      puts "File URL: #{blob.url}"
      
      # Clean up
      blob.purge
      test_file.close
      test_file.unlink
      
    rescue => e
      puts "❌ R2 configuration failed:"
      puts "Error: #{e.message}"
      puts "Make sure you have configured your R2 credentials properly."
      puts "See CLOUDFLARE_R2_SETUP.md for setup instructions."
    end
  end
  
  desc "Show R2 configuration status"
  task status: :environment do
    puts "R2 Configuration Status:"
    puts "Active Storage Service: #{Rails.application.config.active_storage.service}"
    
    if Rails.application.credentials.dig(:r2, :access_key_id)
      puts "✅ R2 credentials found in Rails credentials"
    else
      puts "❌ R2 credentials not found in Rails credentials"
    end
    
    if ENV['R2_ACCESS_KEY_ID']
      puts "✅ R2 environment variables found"
    else
      puts "❌ R2 environment variables not found"
    end
  end
end 
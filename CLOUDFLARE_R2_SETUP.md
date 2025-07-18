# Cloudflare R2 Setup for Rails Active Storage

This guide explains how to set up Cloudflare R2 for file storage in your Rails application.

## Prerequisites

1. A Cloudflare account
2. R2 bucket created in your Cloudflare dashboard
3. API tokens with R2 permissions

## Step 1: Create R2 Bucket

1. Go to your Cloudflare dashboard
2. Navigate to R2 Object Storage
3. Create a new bucket for your application
4. Note down your Account ID (found in the dashboard sidebar)

## Step 2: Create API Token

1. In Cloudflare dashboard, go to "My Profile" > "API Tokens"
2. Create a new token with the following permissions:
   - Account > Cloudflare R2 > Edit
   - Zone > Zone Settings > Edit (if you want to use custom domains)
3. Save the token securely

## Step 3: Configure Rails Credentials

Run the following command to edit your Rails credentials:

```bash
bin/rails credentials:edit
```

Add the following configuration:

```yaml
r2:
  access_key_id: YOUR_R2_ACCESS_KEY_ID
  secret_access_key: YOUR_R2_SECRET_ACCESS_KEY
  account_id: YOUR_CLOUDFLARE_ACCOUNT_ID
  bucket_name: YOUR_BUCKET_NAME
```

## Step 4: Install Dependencies

Run the following command to install the AWS SDK:

```bash
bundle install
```

## Step 5: Environment Variables (Alternative)

If you prefer using environment variables instead of Rails credentials, you can set:

```bash
export R2_ACCESS_KEY_ID=your_access_key_id
export R2_SECRET_ACCESS_KEY=your_secret_access_key
export R2_ACCOUNT_ID=your_account_id
export R2_BUCKET_NAME=your_bucket_name
```

Then update `config/storage.yml` to use environment variables:

```yaml
r2:
  service: S3
  access_key_id: <%= ENV['R2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['R2_SECRET_ACCESS_KEY'] %>
  endpoint: https://<%= ENV['R2_ACCOUNT_ID'] %>.r2.cloudflarestorage.com
  region: auto
  bucket: <%= ENV['R2_BUCKET_NAME'] %>
```

## Step 6: Test Configuration

You can test your R2 configuration by running:

```bash
bin/rails console
```

Then in the console:

```ruby
# Test file upload
file = File.open(Rails.root.join('README.md'))
blob = ActiveStorage::Blob.create_and_upload!(
  io: file,
  filename: 'test.txt',
  content_type: 'text/plain'
)
puts "File uploaded successfully: #{blob.url}"
```

## Step 7: Optional - Custom Domain

If you want to use a custom domain for your R2 bucket:

1. In your R2 bucket settings, add a custom domain
2. Update your storage configuration to use the custom domain:

```yaml
r2:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:r2, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:r2, :secret_access_key) %>
  endpoint: https://your-custom-domain.com
  region: auto
  bucket: <%= Rails.application.credentials.dig(:r2, :bucket_name) %>
```

## Security Considerations

1. Never commit your R2 credentials to version control
2. Use Rails credentials or environment variables for sensitive data
3. Regularly rotate your API tokens
4. Set appropriate CORS policies in your R2 bucket if needed

## Troubleshooting

### Common Issues

1. **403 Forbidden**: Check your API token permissions
2. **Bucket not found**: Verify your bucket name and account ID
3. **SSL errors**: Ensure your endpoint URL is correct

### Debug Mode

To debug R2 issues, you can temporarily enable debug logging:

```ruby
# In config/environments/production.rb
config.log_level = :debug
```

## Migration from Local Storage

If you're migrating from local storage to R2:

1. Update your production configuration to use R2
2. Consider using Active Storage's mirror service during transition
3. Migrate existing files using Active Storage's built-in migration tools

## Performance Tips

1. Use CDN for better global performance
2. Consider using Active Storage variants for image optimization
3. Set appropriate cache headers for your use case
4. Use background jobs for large file uploads

## Cost Optimization

1. Monitor your R2 usage in the Cloudflare dashboard
2. Set up billing alerts
3. Consider lifecycle policies for old files
4. Use appropriate storage classes for different file types 
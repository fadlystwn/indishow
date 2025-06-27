# Procfile Configuration

This Rails application includes several Procfile configurations for different deployment scenarios:

## Files Overview

### `Procfile` (Production)
The main Procfile for production deployments (Heroku, Railway, etc.)
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate && bundle exec rails assets:precompile
```

### `Procfile.dev` (Development)
Local development with Foreman
```
web: bin/rails server
css: bin/rails tailwindcss:watch
```

### `Procfile.heroku` (Heroku-specific)
Extended configuration for Heroku with additional processes
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
scheduler: bundle exec sidekiq-cron
release: bundle exec rails db:migrate && bundle exec rails assets:precompile
console: bundle exec rails console
```

## Process Types

- **web**: Runs the Puma web server with production configuration
- **worker**: Runs Sidekiq for background job processing
- **release**: Runs database migrations and asset compilation before deployment
- **scheduler**: (Optional) Runs recurring background jobs with sidekiq-cron
- **console**: (Optional) Provides Rails console access

## Environment Variables

Make sure to set these environment variables in production:

- `REDIS_URL`: Redis connection URL for Sidekiq and caching
- `RAILS_MASTER_KEY`: For decrypting credentials
- `DATABASE_URL`: Database connection (usually set automatically by platform)
- `RAILS_ENV=production`
- `RACK_ENV=production`

### Optional Environment Variables

- `WEB_CONCURRENCY`: Number of Puma worker processes (default: 2)
- `RAILS_MAX_THREADS`: Max threads per worker (default: 3)
- `SIDEKIQ_USERNAME` & `SIDEKIQ_PASSWORD`: For securing Sidekiq web UI

## Deployment Commands

### Using Foreman (Development)
```bash
# Install foreman if not already installed
gem install foreman

# Run development processes
foreman start -f Procfile.dev
```

### Using Heroku CLI
```bash
# Deploy to Heroku
git push heroku main

# Scale workers
heroku ps:scale worker=1

# View logs
heroku logs --tail

# Access Sidekiq web interface
# Visit: https://your-app.herokuapp.com/sidekiq
```

### Manual Process Management
```bash
# Start web server
bundle exec puma -C config/puma.rb

# Start background worker
bundle exec sidekiq -C config/sidekiq.yml

# Run migrations
bundle exec rails db:migrate
```

## Monitoring

- **Sidekiq Web UI**: Available at `/sidekiq` (secured in production)
- **Health Check**: Available at `/up`
- **Puma Stats**: Available through Puma's built-in stats server

## Configuration Files

- `config/puma.rb`: Web server configuration
- `config/sidekiq.yml`: Background job configuration
- `config/initializers/sidekiq.rb`: Redis connection setup
- `config/application.rb`: Active Job adapter configuration

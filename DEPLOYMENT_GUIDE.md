# 🚀 Rails Deployment Guide

Your Rails application is now fully configured for production deployment with a complete Procfile setup!

## ✅ What's Been Configured

### Process Management
- **Production Procfile** with web, worker, and release processes
- **Development Procfile** for local development
- **Heroku-specific Procfile** with additional processes
- **Puma web server** optimized for production clustering
- **Sidekiq background jobs** with Redis integration
- **Automated migrations** and asset compilation on deployment

### Key Features
- 🌐 **Multi-worker Puma setup** for high concurrency
- 🔄 **Background job processing** with Sidekiq
- 📊 **Job monitoring** via Sidekiq Web UI at `/sidekiq`
- 🗄️ **Redis caching** for improved performance
- 🔒 **Security configurations** for production
- 📝 **Comprehensive logging** and health checks

## 🛠️ Quick Start Commands

### Local Development
```bash
# Start all development processes
foreman start -f Procfile.dev

# Or start individual processes
bin/rails server              # Web server
bin/rails tailwindcss:watch   # CSS compilation
```

### Production Testing
```bash
# Test the production Procfile locally
foreman start -f Procfile

# Test individual production processes
bundle exec puma -C config/puma.rb
bundle exec sidekiq -C config/sidekiq.yml
```

### Deployment Commands

#### Heroku Deployment
```bash
# Initial setup
heroku create your-app-name
heroku addons:create heroku-redis:mini

# Deploy
git push heroku main

# Scale processes
heroku ps:scale web=1 worker=1

# Check status
heroku ps
heroku logs --tail

# Access Sidekiq monitoring
open https://your-app.herokuapp.com/sidekiq
```

#### Railway Deployment
```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway init
railway up
```

#### Docker Deployment
```bash
# Build and run
docker build -t indishow .
docker run -p 3000:3000 -e RAILS_ENV=production indishow
```

## 🔧 Environment Variables

### Required for Production
```bash
RAILS_ENV=production
RACK_ENV=production
RAILS_MASTER_KEY=your_master_key_here
DATABASE_URL=postgres://user:pass@host:port/dbname
REDIS_URL=redis://localhost:6379/0
```

### Optional Configuration
```bash
WEB_CONCURRENCY=2              # Number of Puma workers
RAILS_MAX_THREADS=3            # Threads per worker
PORT=3000                      # Web server port
RAILS_LOG_LEVEL=info           # Logging level
SIDEKIQ_USERNAME=admin         # Sidekiq UI auth (optional)
SIDEKIQ_PASSWORD=secret        # Sidekiq UI auth (optional)
```

## 📊 Monitoring & Health Checks

### Application Health
- **Health endpoint:** `GET /up`
- **Sidekiq monitoring:** `GET /sidekiq`
- **Application logs:** Check platform-specific logging

### Performance Monitoring
```bash
# Heroku
heroku logs --tail --dyno=web
heroku logs --tail --dyno=worker

# Check memory usage
heroku ps:exec --dyno=web
```

## 🔍 Troubleshooting

### Common Issues

#### Web Process Won't Start
```bash
# Check Puma configuration
bundle exec puma -C config/puma.rb --help

# Verify environment variables
heroku config                # Heroku
printenv | grep RAILS        # Local
```

#### Background Jobs Not Processing
```bash
# Check Redis connection
redis-cli ping

# Verify Sidekiq configuration
bundle exec sidekiq -C config/sidekiq.yml --help

# Check job queue
# Visit /sidekiq in your browser
```

#### Database Issues
```bash
# Run migrations manually
heroku run rails db:migrate   # Heroku
RAILS_ENV=production bundle exec rails db:migrate  # Local
```

#### Asset Compilation Fails
```bash
# Precompile assets manually
RAILS_ENV=production bundle exec rails assets:precompile

# Clean and retry
bundle exec rails assets:clobber
```

## 📋 Process Types Explained

| Process | Command | Purpose | Scaling |
|---------|---------|---------|---------|
| **web** | `bundle exec puma -C config/puma.rb` | Handles HTTP requests | Scale based on traffic |
| **worker** | `bundle exec sidekiq -C config/sidekiq.yml` | Background job processing | Scale based on job volume |
| **release** | `rails db:migrate && rails assets:precompile` | Runs before deployment | Runs once per deploy |
| **scheduler** | `bundle exec sidekiq-cron` | Recurring/scheduled jobs | Usually 1 instance |

## 🎯 Best Practices

### Scaling Guidelines
- **Web processes:** Start with 1-2, scale based on response times
- **Worker processes:** 1 worker per 100-200 jobs/minute
- **Database connections:** Ensure pool size ≥ (web_processes × threads) + worker_processes

### Security
- Always use environment variables for secrets
- Enable SSL in production (`config.force_ssl = true`)
- Secure Sidekiq web interface with authentication
- Regular security updates (`bundle audit`)

### Performance
- Enable caching in production (Redis-backed)
- Use CDN for static assets
- Monitor memory usage and optimize N+1 queries
- Set up proper database indexing

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs for specific error messages
3. Verify all environment variables are set correctly
4. Test locally with production configuration

Your application is production-ready! 🎉

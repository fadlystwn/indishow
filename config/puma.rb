# Puma configuration file.

# Threads per worker
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Bind to the correct interface and port based on environment
if ENV.fetch("RAILS_ENV", "development") == "production"
  bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 8080)}"
else
  port ENV.fetch("PORT", 3000) # For local dev: `rails s` listens on port 3000
end

# Restart command support (rails restart)
plugin :tmp_restart

# Use multiple workers in production
if ENV.fetch("RAILS_ENV", "development") == "production"
  workers ENV.fetch("WEB_CONCURRENCY", 2)
  preload_app!
end

# Optional PID file
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# Set environment explicitly
environment ENV.fetch("RAILS_ENV", "development")

# Disable Puma logging in production
quiet ENV.fetch("RAILS_ENV", "development") == "production"

# Optional: bind HTTPS for dev/test using self-signed certs (only if certs exist)
if ENV["SSL_KEY_PATH"] && ENV["SSL_CERT_PATH"]
  ssl_bind "0.0.0.0", ENV.fetch("SSL_PORT", 3001), {
    key: ENV["SSL_KEY_PATH"],
    cert: ENV["SSL_CERT_PATH"],
    verify_mode: "none"
  }
end

# Called when a worker boots (used in clustered mode)
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

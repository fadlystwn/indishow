# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# to prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Bind to all interfaces in production, localhost in development
bind_to = ENV.fetch("RAILS_ENV", "development") == "production" ? "0.0.0.0" : "127.0.0.1"
bind "tcp://#{bind_to}:#{ENV.fetch('PORT', 3000)}"

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Bind to all interfaces in production, localhost in development
bind_to = ENV.fetch("RAILS_ENV", "development") == "production" ? "0.0.0.0" : "127.0.0.1"
bind "tcp://#{bind_to}:#{ENV.fetch('PORT', 3000)}"

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers ENV.fetch("WEB_CONCURRENCY", 2)

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV", "development")

# Disable request logging in production for performance
quiet ENV.fetch("RAILS_ENV", "development") == "production"

# Configure SSL (optional)
ssl_bind '0.0.0.0', ENV.fetch("SSL_PORT", 3001), {
  key: ENV["SSL_KEY_PATH"],
  cert: ENV["SSL_CERT_PATH"],
  verify_mode: 'none'
} if ENV["SSL_KEY_PATH"] && ENV["SSL_CERT_PATH"]

# Worker and master process callbacks
on_worker_boot do
  # Worker specific setup for Rails 4.1+
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

before_fork do
  # Close database connections before forking
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

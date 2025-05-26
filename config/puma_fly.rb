# Puma configuration optimized for Fly.io
# Based on the default Rails Puma config with Fly.io specific modifications

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# For Fly.io, we typically use fewer workers due to limited memory
workers_count = ENV.fetch("WEB_CONCURRENCY", 1).to_i
workers workers_count if workers_count > 1

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV", "development")

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# The minimum number of threads to use to answer requests.
# The default is "0".
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", 5).to_i

# The maximum number of threads to use to answer requests.
# The default is "5".
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads min_threads_count, max_threads_count

# Bind to all interfaces in production for Fly.io
if ENV.fetch("RAILS_ENV", "development") == "production"
  bind "tcp://0.0.0.0:#{ENV.fetch("PORT", 3000)}"
end

# Preload the application before starting the server.
# This is recommended for Fly.io to reduce memory usage.
preload_app!

# Worker timeout for Fly.io (longer timeout for initial requests)
worker_timeout 60

# Enable worker killer to manage memory usage on Fly.io
before_fork do
  # Close database connections
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  # Re-establish database connections
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Fly.io specific: Graceful shutdown handling
on_worker_shutdown do
  puts "Worker #{Process.pid} shutting down gracefully..."
end

# Health check endpoint
app do |env|
  if env['PATH_INFO'] == '/up'
    [200, {}, ['OK']]
  else
    [404, {}, ['Not Found']]
  end
end

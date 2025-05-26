# Puma configuration optimized for Render deployment
# frozen_string_literal: true

require_relative 'dotenv'

# Thread configuration
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

# Worker timeout for development
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

# Port configuration - Render provides PORT environment variable
port ENV.fetch('PORT', 3000)

# Environment
environment ENV.fetch('RAILS_ENV', 'development')

# Disable pidfile for containerized deployments
@options[:pidfile] = false

# Worker configuration
if ENV['WEB_CONCURRENCY_AUTO'] == 'true'
  require 'etc'
  workers Etc.nprocessors
else
  workers ENV.fetch('WEB_CONCURRENCY', 0)
end

# Preload app for better memory usage with workers
preload_app! if ENV.fetch('WEB_CONCURRENCY', 0).to_i > 0

# Only enable plugins for non-multitenant setups or demo
# Temporarily disable these plugins for Render deployment stability
# if ENV['MULTITENANT'] != 'true' || ENV['DEMO'] == 'true'
#   require_relative '../lib/puma/plugin/redis_server'
#   require_relative '../lib/puma/plugin/sidekiq_embed'
#   plugin :sidekiq_embed
#   plugin :redis_server
# end

# Render-specific optimizations
if ENV['RENDER']
  # Bind to all interfaces
  bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 3000)}"
  
  # Log configuration
  stdout_redirect '/app/log/puma_access.log', '/app/log/puma_error.log', true
  
  # Health check endpoint
  lowlevel_error_handler do |e|
    [500, {}, ["Internal Server Error"]]
  end
end

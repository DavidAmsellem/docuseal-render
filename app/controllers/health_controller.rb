# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def show
    render json: {
      status: 'ok',
      timestamp: Time.current,
      database: database_status,
      redis: redis_status
    }, status: :ok
  rescue => e
    render json: {
      status: 'error',
      timestamp: Time.current,
      error: e.message
    }, status: :service_unavailable
  end

  private

  def database_status
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue => e
    "error: #{e.message}"
  end

  def redis_status
    return 'not configured' unless defined?(Redis)
    
    redis = Redis.new(url: ENV.fetch('REDIS_URL', nil))
    redis.ping
    'connected'
  rescue => e
    "error: #{e.message}"
  end
end

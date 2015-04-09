# From https://github.com/resque/resque-scheduler#resque-pool-integration
task 'resque:pool:setup' do
  Resque::Pool.after_prefork do |job|
    Resque.redis.client.reconnect
  end
end

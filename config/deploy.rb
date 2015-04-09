# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'mira'
set :scm, :git
set :repo_url, 'https://github.com/curationexperts/mira.git'
#set :repo_url, 'git@github.com/curationexperts/mira.git'
set :branch, 'master'
set :deploy_to, '/opt/mira'
set :log_level, :debug
set :keep_releases, 5

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/initializers/devise.rb config/initializers/secret_token.rb config/application.yml config/database.yml config/devise.yml config/fedora.yml config/resque-pool.yml config/redis.yml config/solr.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        execute :rake, 'tmp:clear'
      end
    end
  end

end

source 'https://rubygems.org'

gem 'rails', '4.1.6'

gem 'mysql2'

gem 'hydra-head', '~> 7.2.1'
gem 'blacklight', '~> 5.7.1'
gem 'rsolr', '1.0.10' # avoid a bunch of deprecation warnings. This can be removed when Active-Fedora is updated.
gem 'active-fedora', '~> 7.1.1'
gem 'hydra-editor', '~> 0.5.0'
gem 'hydra-role-management', '0.2.0'
gem 'hydra-batch-edit', '1.1.1'
gem 'qa', '0.3.0'

gem 'sanitize', '2.0.6'

gem 'disable_assets_logger', group: :development

gem 'sass-rails',   '~> 4.0.0'
gem 'coffee-rails', '~> 4.0.0'
gem "bootstrap-sass"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', :platforms => :ruby
gem 'resque-pool'

gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem "jquery-fileupload-rails"

gem "devise"
gem 'bootstrap_form'
gem 'rmagick', '2.13.2', require: 'RMagick'
gem 'resque-status'
gem 'carrierwave', '~> 0.10.0'

gem 'blacklight_advanced_search'
gem 'tufts_models', github: 'curationexperts/tufts_models', ref: 'v4.0.0.rc2'
# gem 'handle-system', '~> 0.0.7'
gem 'handle-system', github: 'jcoyne/handle', ref: '75986ee'

group :development do
  gem 'jettywrapper'
  gem 'capistrano'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.2'
  gem 'sqlite3'
  gem 'spring', '~> 1.3.6'
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem 'webmock'
  gem 'database_cleaner'
  gem 'rspec-activemodel-mocks'
end

group :debug do
  gem 'launchy'
  gem 'byebug', require: false
end

gem 'chronic' # for lib/tufts/model_methods.rb
gem 'titleize' # for lib/tufts/model_methods.rb
gem 'settingslogic' # for settings

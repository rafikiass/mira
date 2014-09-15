source 'https://rubygems.org'

gem 'rails', '4.0.5'

gem 'sqlite3'
gem 'mysql2'

gem 'hydra', '7.1.0'
gem 'hydra-role-management', '0.2.0'
gem 'hydra-editor', '~> 0.5.0'
gem 'hydra-batch-edit', '1.1.1'
gem 'qa', '0.0.3'
gem 'sanitize', '2.0.6'

gem 'disable_assets_logger', group: :development

gem 'sass-rails',   '~> 4.0.0'
gem 'coffee-rails', '~> 4.0.0'
gem "bootstrap-sass"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', :platforms => :ruby

gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem "jquery-fileupload-rails"

gem "devise"
gem 'bootstrap_form'
gem 'rmagick', '2.13.2', require: 'RMagick'
gem 'resque-status'
gem 'carrierwave', '~> 0.10.0'

gem 'blacklight_advanced_search', github: 'projectblacklight/blacklight_advanced_search', branch: 'generate_overrides'
gem 'tufts_models', github: 'curationexperts/tufts_models'

group :development do
  gem 'jettywrapper'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.99'
  gem 'capybara'
  gem 'factory_girl_rails'
end

group :debug do
  gem 'unicorn'
  gem 'launchy'
  gem 'byebug', require: false
end

gem 'chronic' # for lib/tufts/model_methods.rb
gem 'titleize' # for lib/tufts/model_methods.rb
gem 'settingslogic' # for settings

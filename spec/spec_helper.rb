# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

def clean_up_carrierwave_files
  FileUtils.rm_rf(CarrierWave::Uploader::Base.root)
end

require 'byebug' unless ENV['CI']

require 'webmock/rspec'

# Checks for pending migrations before tests are run.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include FactoryGirl::Syntax::Methods

  config.include Devise::TestHelpers, :type => :controller

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.before(:suite) do
    WebMock.allow_net_connect!
    clean_fedora_and_solr
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    clean_up_carrierwave_files
  end

  config.before :each do |v|
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    DatabaseCleaner.start
    WebMock.allow_net_connect!
  end

  config.before type: :view do
    # View tests should never hit fedora/solr, it's all mocked.
    WebMock.disable_net_connect!
  end

  config.after do
    DatabaseCleaner.clean
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #
  config.order = "random"

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explictly tag your specs with their type, e.g.:
  #
  #     describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/v/3-0/docs
  config.infer_spec_type_from_file_location!
end

def find_or_create_ead(pid)
  if TuftsEAD.exists?(pid)
    TuftsEAD.find(pid)
  else
    TuftsEAD.create!(pid: pid, title: "Test #{pid}", displays: ['dl'])
  end
end

def clean_fedora_and_solr
  ActiveFedora::Base.delete_all
  solr = ActiveFedora::SolrService.instance.conn
  solr.delete_by_query("*:*", params: { commit: true })
end


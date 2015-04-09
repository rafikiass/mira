namespace :config do
  desc "copy sample application config files"
  task :copy do
    %w(initializers/secret_token.rb database.yml solr.yml resque-pool.yml redis.yml fedora.yml devise.yml).each do |file|
      puts `cp -v "config/#{file}.sample" "config/#{file}"`
    end

    puts
    puts "Configs copied. Remember to generate a new id for config/devise.yml and config/initializers/secret_token.rb using:"
    puts " $ rake secret"
  end
end

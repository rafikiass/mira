namespace :config do
  desc "copy sample application config files"
  task :copy do
    %w(secrets.yml database.yml solr.yml resque-pool.yml redis.yml fedora.yml devise.yml).each do |file|
      puts `cp -v "config/#{file}.sample" "config/#{file}"`
    end

    puts
    puts "Configs copied. Remember to generate a new id for config/devise.yml and config/secrets.yml using:"
    puts " $ rake secret"
  end
end

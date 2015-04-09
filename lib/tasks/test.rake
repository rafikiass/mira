require 'jettywrapper'

desc 'Run the default CI configuration'
task :ci => [:jetty, 'jetty:config'] do
  Jettywrapper.wrap(Jettywrapper.load_config) do
    Rake::Task['spec'].invoke
  end
end

desc 'Install hydra-jetty (download if necessary)'
task :jetty do
  unless File.exist?('jetty')
    puts "Downloading jetty - wrapper_version: #{Jettywrapper.hydra_jetty_version}"
    `rails generate hydra:jetty`
  end
end

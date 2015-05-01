namespace :handle do
  # When you run:
  #   rake handle:register[tufts:123.456]
  #
  # It will load that object and register a pid for it.
  desc 'Registers a handle for the object. Supply a pid.'
  task :register, [:pid] => :environment do |t, args|
    puts "Registering a handle for #{args[:pid]}"
    begin
      object = ActiveFedora::Base.find(args[:pid])
      RegisterHandleService.new(object).run
    rescue ActiveFedora::ObjectNotFoundError
      $stderr.puts "Unable to find the object for #{args[:pid]}"
    end
  end
end

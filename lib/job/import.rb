module Job
  class Import
    include Resque::Plugins::Status

    def self.queue
      :import
    end

    def self.create(options)
      required = [:record_id, :user_id, :batch_id]

      required.each do |r|
        raise ArgumentError.new("Required keys: #{r}") unless options[r]
      end

      super
    end

    def perform
      tick # give resque-status a chance to kill this

      ImportService.new(pid: options['record_id'], batch_id: options['batch_id']).run
    end

  end
end

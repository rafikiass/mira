module Job
  class RegisterHandle
    include Resque::Plugins::Status

    def self.queue
      :handle
    end

    def self.create(options)
      required = [:record_id]
      raise ArgumentError.new("Required keys: #{required}") if (required - options.keys).present?
      super
    end

    def perform
      object = ActiveFedora::Base.find(options['record_id'])
      RegisterHandleService.new(object).run
    end
  end
end

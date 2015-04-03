module Job
  class CreateDerivatives
    include Resque::Plugins::Status

    def self.queue
      :derivatives
    end

    attr_accessor :record_id, :record

    def self.create(options)
      raise ArgumentError.new("Must supply a record_id") if options[:record_id].blank?
      super
    end

    def perform
      record = ActiveFedora::Base.find(options['record_id'], cast: true)

      begin
        record.create_derivatives
      rescue StandardError => ex
        Notifier.derivatives_failure({:pid => options['record_id'], :message => ex.message})
        raise(ex)
      end

      record.save(validate: false)
    end
  end
end

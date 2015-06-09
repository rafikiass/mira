module Job
  class Import
    include Resque::Plugins::Status
    include RunAsBatchItem

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

      run_as_batch_item(options['record_id'], options['batch_id']) do |record, batch|
# TODO pass record?
        ImportService.new(record: record, batch: batch).run
      end
    end

  end
end

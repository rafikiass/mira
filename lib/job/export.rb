module Job
  class Export
    include Resque::Plugins::Status

    def self.queue
      :export
    end

    def self.create(options)
      required = [:record_ids, :user_id, :datastream_ids, :batch_id]

      required.each do |r|
        raise ArgumentError.new("Required keys: #{r}") unless options[r]
      end

      super
    end

    def perform
      tick # give resque-status a chance to kill this

      DraftExportService.new({
        record_ids: options['record_ids'],
        datastream_ids: options['datastream_ids'],
        batch_id: options['batch_id']
      }).run
    end

  end
end

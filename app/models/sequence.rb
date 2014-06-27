class Sequence < ActiveRecord::Base
  def self.next_val(options = {})
    namespace = options.fetch(:namespace, 'tufts')
    name = options.fetch(:name, nil)
    format = options.fetch(:format, 'sd.%07d')
    pid_format = namespace + ":" + format
    seq = Sequence.where(name: name).first_or_create

    seq.with_lock do
      seq.value += 1
      seq.save!
    end
    sprintf(pid_format, seq.value)
  end
end

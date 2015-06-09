require 'handle'
class RegisterHandleService
  attr_reader :object, :messages

  # @param [ActiveFedora::Base] object the object to generate a handle for.
  def initialize(object)
    @object = object
  end

  def run
    handle = generate_handle
    record = build_record(handle)
    begin
      record.save
      RecordHandleService.new(object, "http://hdl.handle.net/#{handle}").run
    rescue Handle::HandleError => e
      message = "Unable to register handle #{handle} for #{object.pid}\n#{e.message}"
      HandleLogService.log(nil, object.pid, message)
      raise e
    end
  end

  private

    def build_record(handle)
      conn = Handle::Connection.new(admin, 300, key_path, passphrase)

      conn.create_record(handle).tap do |record|
        record.add(:URL, url).index = 2
        record.add(:Email, email).index = 6
        record << Handle::Field::HSAdmin.new(admin)
      end
    end

    def passphrase
      Rails.application.secrets.handle_passphrase
    end

    # @example 0.NA/10427.TEST
    def admin
      Settings.handle_admin
    end

    def email
      Settings.handle_email
    end

    def key_path
      Settings.handle_private_key
    end

    def batch_tool_path
      Settings.handle_batch_tool
    end

    def handle_prefix
      Settings.handle_prefix
    end

    def generate_handle
      "#{handle_prefix}/#{sequence_number}"
    end

    def sequence_number
      Sequence.next_val(scope: 'handle', format: '%06d')
    end

    def url
      "http://dl.tufts.edu/catalog/#{PidUtils.to_published(object.id)}"
    end
end


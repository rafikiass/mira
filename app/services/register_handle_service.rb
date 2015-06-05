require 'handle'
class RegisterHandleService
  attr_reader :object, :messages

  # @param [ActiveFedora::Base] object the object to generate a handle for.
  def initialize(object)
    @object = object
  end

  def run
    handle = generate_handle
    if build_record(handle).save
      RecordHandleService.new(object, "http://hdl.handle.net/#{handle}").run
    else
      message = "Unable to register handle #{handle} for #{object.pid}"
      HandleLogService.log(nil, object.pid, message)
      raise HandleServiceError, message
    end
  end

  private

    def build_record(handle)
      conn = Handle::Connection.new(admin, 300, key_path, password)

      conn.create_record(handle).tap do |record|
        record.add(:URL, url).index = 2
        record.add(:Email, email).index = 6
        record << Handle::Field::HSAdmin.new(admin)
      end
    end

    def password
      Rails.application.secrets.handle_password
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

    def namespace
      Settings.handle_namespace
    end

    def generate_handle
      "#{namespace}/#{sequence_number}"
    end

    def sequence_number
      Sequence.next_val(scope: 'handle', format: '%06d')
    end

    def url
      "http://dl.tufts.edu/catalog/#{PidUtils.to_published(object.id)}"
    end
    # Raised when there is a problem registering the handle
    class HandleServiceError < StandardError
    end
end


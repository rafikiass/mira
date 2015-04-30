class RegisterHandleService
  attr_reader :object, :messages

  def initialize(object)
    @object = object
  end

  def run
    handle = generate_handle
    file_name = BatchFileGenerator.new(handle, url, key_path, password).generate
    if register_handle(file_name)
      record_handle(handle)
    else
      raise HandleServiceError, "Unable to register handle #{handle} for #{object.pid}\n#{messages}"
    end
  end

  private
    def password
      Rails.application.secrets.handle_password
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

    # Return true on success, false on failure
    def register_handle(file_name)
      @messages = run_command
      !/FAILURE/.match(@messages)
    end

    # Returns the STDOUT captured from running the batch tool
    # The command will return output like this:
    #   Batch(/hs/hsj-7.3.1/test/create) process started ...
    #   Batch process prints log on stdout ...
    #   Start Time: Thu Apr 30 15:05:22 UTC 2015
    #   ==>FAILURE[7]: create:10427.TEST/123456: Error(101): HANDLE ALREADY EXISTS
    #   Successes/Total Entries: 0/1
    #   Batch File Lines: 7
    #   Finish Time: Thu Apr 30 15:05:22 UTC 2015
    #   This batch took 0 seconds to complete at an average speed of 3.4843205574912894 operations/second
    #   Batch process finished

    def run_command
      command = "#{batch_tool_path} #{file_name}"
      out = `#{command}`
      raise HandleServiceError, "'#{command}' couldn't be run" unless $?.success?
      out
    end

    def record_handle(handle)
      [object.find_published, object.find_draft].each do |obj|
        update_respecting_published_status(obj) do |item|
          item.update_attributes(handle_attribute => [handle])
        end
      end
    end

    def update_respecting_published_status(obj, &block)
      if obj.published?
        obj.publishing = true
        yield obj
        obj.publishing = false
      else
        yield obj
      end
    end

    def handle_attribute
      :identifier
    end

    def generate_handle
      "#{namespace}/#{sequence_number}"
    end

    def sequence_number
      Sequence.next_val(scope: 'handle', format: '%06d')
    end

    def url
      "http://dl.tufts.edu/catalog/#{object.id}"
    end


    class BatchFileGenerator
      attr_reader :handle, :namespace, :url, :key_path, :password

      def initialize(handle, url, key_path, password)
        @handle = handle
        @namespace = handle.split('/').first
        @url = url
        @key_path = key_path
        @password = password
      end

      def generate
        ensure_dir_exists!
        File.open(file_name, 'w') do |f|
          f.puts auth_header + command(handle)
        end

        file_name
      end

      private
        def ensure_dir_exists!
          FileUtils.mkdir_p(directory)
        end

        def directory
          @directory ||= File.join(Rails.root, 'tmp', 'handle')
        end

        def auth_header
          "AUTHENTICATE PUBKEY:300:0.NA/#{namespace}\n" +
          "#{key_path}|#{password}\n\n"
        end

        def command(handle)
          "#{verb} #{handle}\n" +
          "2 URL 86400 1110 UTF8 #{url}\n\n"
        end

        def verb
          'CREATE'.freeze
        end

        # A unique name by including the timestamp to miliseconds and pid (process id)
        def file_name
          @file_name ||= File.join(directory, "handles-#{timestamp}-#{$$}.txt")
        end

        # An iso8601 timestamp with milliseconds
        def timestamp
          Time.now.iso8601(3).first(23)
        end
    end

    # Raised when there is a problem registering the handle
    class HandleServiceError < StandardError
    end
end


# This class is responsible for recording the provided handle on the draft
# and the published object if it exists
class RecordHandleService
  def initialize(object, handle)
    @object = object
    @handle = handle
  end

  def run
    record_handle_on_draft_version
    record_handle_on_published_version
  end

  private
    def record_handle_on_draft_version
      record_handle(@object.find_draft)
    end

    # Handle the case where object is not published
    def record_handle_on_published_version
      record_handle(@object.find_published)
    rescue ActiveFedora::ObjectNotFoundError
    end

    def record_handle(obj)
      update_respecting_published_status(obj) do |item|
        item.update_attributes(handle_attribute => [@handle])
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
end

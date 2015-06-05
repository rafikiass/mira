class PublishService < WorkflowService
  def initialize(*)
    super
    raise UnpublishableModelError unless object.publishable?
  end

  def run
    published_pid = PidUtils.to_published(object.pid)

    destroy_published_version!
    FedoraObjectCopyService.new(object.class, from: object.pid, to: published_pid).run

    published = object.class.find(published_pid)
    published!(published, user)
    published!(object, user)
    audit('Published')
    register_handle
  end

  private

    def register_handle
      return if has_handle? || !displays_in_dl?
      Job::RegisterHandle.create(record_id: object.id)
    end

    def displays_in_dl?
      object.displays.include?('dl')
    end

    def has_handle?
      object.identifier.reject(&:blank?).present?
    end

    # Mark that this object has been published
    def published!(obj, user)
      obj.publishing = true
      obj.save!
      obj.publishing = false
    end

end

class UnpublishableModelError < StandardError
  def message
    'Templates cannot be published'
  end
end


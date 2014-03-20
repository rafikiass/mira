class TuftsTemplate < ActiveFedora::Base
  include BaseModel

  has_attributes :template_name, datastream: 'DCA-ADMIN', multiple: false
  validates :template_name, presence: true

  def push_to_production!
    # Templates should never be pushed to the production
    # environment.  They are meant to be used by admin users
    # to ingest files in bulk and apply the same metadata to
    # many files.  There should be no need for them to be
    # visible to general users.
    raise UnpublishableModelError.new
  end

  def published?
    false
  end

  def queue_jobs_to_apply_template(user_id, record_ids)
    attrs = attributes_to_update
    return if attrs.empty?

    record_ids.each do |id|
      job = Job::ApplyTemplate.new(user_id, id, attrs)
      Tufts.queue.push(job)
    end
  end

  def attributes_to_update
    attrs = terms_for_editing.inject({}) do |attrs, attribute|
      value_of_attr = self.send(attribute)
      unless attr_empty?(value_of_attr)
        attrs.merge!(attribute => value_of_attr)
      end
      attrs
    end

    unless attr_empty?(stored_collection_id)
      attrs.merge!(stored_collection_id: stored_collection_id)
    end

    attrs
  end

private

  def attr_empty?(value)
    Array(value).all?{|x| x.blank? }
  end

end


class UnpublishableModelError < StandardError
  def message
    'Templates cannot be pushed to production'
  end
end
module AttachmentsHelper
  def render_files_form(obj)
    if lookup_context.find_all("attachments/files_form/_#{obj.class.model_name.singular}").any?
      render "attachments/files_form/#{obj.class.model_name.singular}"
    else
      render "attachments/files_form/default"
    end
  end
end

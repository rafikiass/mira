class TemplatesController < CatalogController
  load_and_authorize_resource only: [:create, :destroy], class: TuftsTemplate

  # Since TuftsTemplates behave just like other fedora
  # objects, most of the template actions are handled by
  # either the CatalogController or the RecordsController.

  TemplatesController.solr_search_params_logic += [:only_templates]

  def create
    @template.save(validate: false)
    redirect_to hydra_editor.edit_record_path(@template)
  end

  def destroy
    # set the flash using the title, before we delete it and the title is not available.
    flash[:notice] = "\"#{@template.template_name}\" has been purged"
    @template.destroy
    redirect_to templates_path
  end

  protected

    def only_templates(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "active_fedora_model_ssi:TuftsTemplate"
    end

    def filter_templates
      # Clears the Template filter set in the CatalogController
    end

    def only_draft_objects(solr_parameters, user_parameters)
      # nop - override method from CatalogController
    end

end

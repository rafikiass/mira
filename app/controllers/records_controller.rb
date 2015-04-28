class RecordsController < ApplicationController
  include RecordsControllerBehavior

  before_filter :load_object, only: [:review, :cancel]
  authorize_resource only: [:review]
  load_and_authorize_resource only: [:publish, :unpublish, :revert, :destroy]

  # We don't even want them to see the 'choose_type' page if they can't create
  prepend_before_filter :ensure_can_create, only: :new

  def edit
    if @record.respond_to?(:draft?) && !@record.draft?
      redirect_to hydra_editor.edit_record_path(PidUtils.to_draft(@record.pid))
    else
      super
    end
  end

  def update
    @record = @record.find_draft if @record.respond_to?(:find_draft)
    super
  end

  def new
    unless has_valid_type?
      render 'choose_type'
      return
    end

    args = params[:pid].present? ? {pid: params[:pid]} : {}

    if !args[:pid] || (args[:pid] && TuftsBase.valid_pid?(args[:pid]))
      if ActiveFedora::Base.exists?(args[:pid])
        flash[:alert] = "A record with the pid \"#{args[:pid]}\" already exists."
        redirect_to hydra_editor.edit_record_path(args[:pid])
      else
        klass = params[:type].constantize
        @record = if klass.respond_to?(:build_draft_version)
                    klass.build_draft_version(args)
                  else
                    klass.new(args)
                  end
        @record.save(validate: false)
        redirect_to next_page
      end
    else
      flash.now[:error] = "You have specified an invalid pid. Pids must be in this format: tufts:1231"
      render 'choose_type'
    end
  end

  def review
    if @record.respond_to?(:reviewed)
      @record.reviewed
      if @record.save
        flash[:notice] = "\"#{@record.title}\" has been marked as reviewed."
      else
        flash[:error] = "Unable to mark \"#{@record.title}\" as reviewed."
      end

    else
      flash[:error] = "Unable to mark \"#{@record.title}\" as reviewed."
    end
    redirect_to catalog_path(@record)
  end

  def publish
    PublishService.new(@record, current_user.id).run
    redirect_to catalog_path(@record), notice: "\"#{@record.title}\" has been pushed to production"
  end

  def unpublish
    # The original id may be of the draft or production pid, but we always redirect to draft
    title = @record.title
    UnpublishService.new(@record, current_user.id).run
    redirect_to catalog_path(PidUtils.to_draft(@record.id)), notice: "\"#{title}\" has been unpublished"
  end

  def revert
    RevertService.new(@record, current_user.id).run
    redirect_to catalog_path(PidUtils.to_draft(@record.id)), notice: "\"#{@record.title}\" has been reverted"
  end

  def destroy
    @record.state = "D"
    @record.save(validate: false)
    PurgeService.new(@record, current_user.id).run if @record.published_at
    if @record.is_a?(TuftsTemplate)
      flash[:notice] = "\"#{@record.template_name}\" has been purged"
      redirect_to templates_path
    else
      flash[:notice] = "\"#{@record.title}\" has been purged"
      redirect_to root_path
    end
  end

  def cancel
    if @record.DCA_META.versions.empty?
      authorize! :destroy, @record
      @record.destroy
    end
    if @record.is_a?(TuftsTemplate)
      redirect_to templates_path
    else
      redirect_to root_path
    end
  end

  def redirect_after_update
    if @record.is_a?(TuftsTemplate)
      templates_path
    else
      main_app.catalog_path @record
    end
  end

  def set_attributes
    resource.state = 'A' if resource.state == 'D'
    resource.working_user = current_user
    # set rightsMetadata access controls
    resource.apply_depositor_metadata(current_user)

    # pull out because it's not a real attribute (it's derived, but still updatable)
    resource.stored_collection_id = raw_attributes.delete(:stored_collection_id).try(&:first)

    resource.datastreams= raw_attributes[:datastreams] if raw_attributes[:datastreams]
    resource.relationship_attributes = raw_attributes['relationship_attributes'] if raw_attributes['relationship_attributes']
    super
  end

  private

  def ensure_can_create
    authorize! :create, ActiveFedora::Base
  end

  def load_object
    @record = ActiveFedora::Base.find(params[:id], cast: true)
  end

  def next_page
    if @record.is_a?(TuftsTemplate)
      hydra_editor.edit_record_path(@record)
    else
      record_attachments_path(@record)
    end
  end

  # Override method from hydra-editor to include rels-ext fields
  # def set_attributes
  #   puts "params #{params}"
  #   rels_ext_fields = { relationship_attributes: params[ActiveModel::Naming.singular(resource)]['relationship_attributes'] }
  #   puts "Rels #{rels_ext_fields}"
  #   resource.attributes = collect_form_attributes.merge(rels_ext_fields)
  # end

end

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

    if params[:pid].present? && !TuftsBase.valid_pid?(params[:pid])
      flash.now[:error] = "You have specified an invalid pid. Pids must be in this format: tufts:1231"
      render 'choose_type'
      return
    end

    if ActiveFedora::Base.exists?(params[:pid])
      flash[:alert] = "A record with the pid \"#{params[:pid]}\" already exists."
      redirect_to hydra_editor.edit_record_path(params[:pid])
    else
      @record = build_record
      if @record.save
        redirect_to next_page
      else
        render 'choose_type'
      end
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
    redirect_to catalog_path(@record), notice: "\"#{@record.title}\" has been published"
  end

  def unpublish
    # The original id may be of the draft or published pid, but we always redirect to draft
    title = @record.title
    UnpublishService.new(@record, current_user.id).run
    redirect_to catalog_path(PidUtils.to_draft(@record.id)), notice: "\"#{title}\" has been unpublished"
  end

  def revert
    RevertService.new(@record, current_user.id).run
    redirect_to catalog_path(PidUtils.to_draft(@record.id)), notice: "\"#{@record.title}\" has been reverted"
  end

  def destroy
    # set the flash using the title, before we delete it and the title is not available.
    if @record.is_a?(TuftsTemplate)
      flash[:notice] = "\"#{@record.template_name}\" has been purged"
    else
      flash[:notice] = "\"#{@record.title}\" has been purged"
    end

    PurgeService.new(@record, current_user.id).run
    if @record.is_a?(TuftsTemplate)
      redirect_to templates_path
    else
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

  protected

    def redirect_after_update
      if @record.is_a?(TuftsTemplate)
        templates_path
      else
        main_app.catalog_path @record
      end
    end


    def set_attributes
      resource.working_user = current_user
      # set rightsMetadata access controls
      resource.apply_depositor_metadata(current_user)

      # pull out because it's not a real attribute (it's derived, but still updatable)
      resource.stored_collection_id = raw_attributes.delete(:stored_collection_id).try(&:first)

      resource.datastreams= raw_attributes[:datastreams] if raw_attributes[:datastreams]
      resource.relationship_attributes = raw_attributes['relationship_attributes'] if raw_attributes['relationship_attributes']
      super
    end

    # Remove any of the blank entries in `displays'
    def collect_form_attributes
      super.tap do |attrs|
        attrs[:displays] = attrs[:displays].reject(&:blank?).uniq if attrs[:displays]
      end
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

  def build_record
    klass = params[:type].constantize
    args = params.slice(:title, :pid).merge(displays: Array(params[:displays]))
    args.delete(:pid) if args[:pid].blank?
    if klass == TuftsTemplate
      # Store the `title` parameter as `template_name`
      args.merge!(template_name: args.delete(:title))
      klass.new(args)
    else
      klass.build_draft_version(args)
    end
  end
end

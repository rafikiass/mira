class BatchesController < ApplicationController
  before_filter :build_batch, only: :create
  load_resource only: [:index, :show, :edit]
  before_filter :paginate, only: :index
  before_filter :load_batch, only: :update
  authorize_resource

  def index
    @batches = @batches.order(created_at: :desc)
  end

  def new_template_import
    @batch = BatchTemplateImport.new
  end

  def create
    case params['batch']['type']
    when 'BatchPublish'
      require_pids_and_run_batch
    when 'BatchUnpublish'
      require_pids_and_run_batch
    when 'BatchPurge'
      require_pids_and_run_batch
    when 'BatchRevert'
      require_pids_and_run_batch
    when 'BatchTemplateUpdate'
      handle_apply_template
    when 'BatchTemplateImport'
      handle_import(:new_template_import)
    else
      flash[:error] = 'Unable to handle batch request.'
      redirect_to (request.referer || root_path)
    end
  end

  def show
    @records_by_pid = (@batch.pids || []).reduce({}) do |acc, pid|
      begin
        r = ActiveFedora::Base.find(pid, cast: true)
        acc.merge(r.pid => r)
      rescue ActiveFedora::ObjectNotFoundError
        acc
      end
    end
  end

  def edit
  end

  def update
    case @batch.type
    when 'BatchTemplateImport'
      handle_update_for_template_import
    else
      flash[:error] = 'Unable to handle batch request.'
      redirect_to (request.referer || root_path)
    end
  end


private

  def build_batch
    @batch = Batch.new(params.require(:batch).permit(:template_id, {pids: []}, :type, :record_type, :behavior))
  end

  def load_batch
    @batch = Batch.lock.find(params.require(:id))
  end

  def paginate
    @batches = @batches.order('created_at DESC').page(params[:page]).per(10)
  end

  def create_and_run_batch
    @batch.creator = current_user

    if @batch.save
      if run_batch
        redirect_to batch_path(@batch)
      else
        flash[:error] = "Unable to run batch, please try again later."
        @batch.delete
        @batch = Batch.new @batch.attributes.except('id')
        render_new_or_redirect
      end
    else
      render_new_or_redirect  # form errors
    end
  end

  def run_batch
    if @batch.type == 'BatchTemplateUpdate'
      BatchTemplateUpdateRunnerService.new(@batch).run
    else
      BatchRunnerService.new(@batch).run
    end
  end

  def render_new_or_redirect
    if @batch.type == 'BatchTemplateUpdate'
      render :new
    else
      redirect_to (request.referer || root_path)
    end
  end

  def no_pids_selected
    flash[:error] = 'Please select some records to do batch updates.'
    redirect_to (request.referer || root_path)
  end

  def require_pids_and_run_batch
    if !@batch.pids.present?
      no_pids_selected
    else
      create_and_run_batch
    end
  end

  def handle_apply_template
    if !@batch.pids.present?
      no_pids_selected
    elsif params[:batch_form_page] == '1' && @batch.template_id.nil?
      render :new
    else
      create_and_run_batch
    end
  end

  def handle_import(form_view)
    @batch.creator = current_user

    if @batch.save
      redirect_to edit_batch_path(@batch)
    else
      render form_view
    end
  end

  def collect_warning(record, doc)
    dsid = record.class.original_file_datastreams.first
    if !record.valid_type_for_datastream?(dsid, doc.content_type)
      "You provided a #{doc.content_type} file, which is not a valid type: #{doc.original_filename}"
    end
  end

  #TODO add transaction around batch. Is this needed?
  #TODO add transaction around everything? Is this possible?
  def handle_update_for_template_import
    if params[:documents].blank?
      # no documents have been passed in
      flash[:error] = "Please select some files to upload."
      render :edit
    else
      action = TemplateImportAction.new(@batch, current_user, params[:documents])
      respond_to_import(action.run, @batch, action.document_statuses)
    end
  end

  def collect_errors(batch, records)
    (batch.errors.full_messages + records.map{|r| r.errors.full_messages }.flatten).compact
  end

  def respond_to_import(successful, batch, document_statuses)
    docs, records, warnings, errors = document_statuses.transpose.map(&:compact)
    respond_to do |format|
      format.html do
        flash[:alert] = (warnings + errors).join(', ')
        if successful
          redirect_to batch_path(@batch)
        else
          render :edit
        end
      end

      format.json do
        json = {
          files: document_statuses.map do |doc, record, warning, error|
            msg = {}
            if record.present?
              msg[:pid] = record.id
              msg[:title] = record.title
            end
            msg[:name] = doc.original_filename
            msg[:warning] = warning if warning.present?
            errors = collect_errors(batch, records)
            errors << error if error.present?
            msg[:error] = errors unless errors.empty?
            msg
          end
        }.to_json

        render json: json
      end
    end
  end
end

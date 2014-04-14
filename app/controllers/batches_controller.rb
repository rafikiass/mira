class BatchesController < ApplicationController
  before_filter :build_batch, only: [:create]
  load_resource only: [:index, :show, :edit]
  before_filter :load_batch, only: [:update]
  authorize_resource

  def index
    @batches = @batches.order(created_at: :desc)
  end

  def new_template_import
    @batch = BatchTemplateImport.new
  end

  def new_xml_import
    @batch = BatchXmlImport.new
  end

  def create
    case params['batch']['type']
    when 'BatchPublish'
      require_pids_and_run_batch
    when 'BatchPurge'
      require_pids_and_run_batch
    when 'BatchTemplateUpdate'
      handle_apply_template
    when 'BatchTemplateImport'
      handle_import(:new_template_import)
    when 'BatchXmlImport'
      handle_import(:new_xml_import)
    else
      flash[:error] = 'Unable to handle batch request.'
      redirect_to (request.referer || root_path)
    end
  end

  def show
    @records_by_pid = ActiveFedora::Base.find(@batch.pids, cast: true).reduce({}) do |acc, record|
      acc.merge(record.id => record)
    end
  end

  def edit
  end

  def update
    case @batch.type
    when 'BatchTemplateImport'
      handle_update_for_template_import
#    when 'BatchXmlImport'
#      handle_update_for_xml_import
    else
      flash[:error] = 'Unable to handle batch request.'
      redirect_to (request.referer || root_path)
    end
  end


private

  def build_batch
    @batch = Batch.new(params.require(:batch).permit(:template_id, {pids: []}, :type, :record_type, :metadata_file))
  end

  def load_batch
    @batch = Batch.find(params.require(:id))
  end

  def create_and_run_batch
    @batch.creator = current_user

    if @batch.save
      if @batch.run
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

  def collect_warnings(record, dsid, doc)
    if !record.valid_type_for_datastream?(dsid, doc.content_type)
      "You provided a #{doc.content_type} file, which is not a valid type: #{doc.original_filename}"
    end
  end

  def collect_errors(records)
    (@batch.errors.full_messages +
        records.map{|r| r.errors.full_messages }.flatten +
        [flash[:error]]).compact
  end

  # TODO: Take a look at the handle_update_for_template_import method, handle_update_for_xml_import method and attachments_controller update method, and see if we can pull out any common code.

  def handle_update_for_template_import
    if params[:documents] && !params[:documents].empty?
      warnings = []
      record_class = @batch.record_type.constantize
      dsid = record_class.original_file_datastreams.first
      attrs = @batch.template.attributes_to_update

      records = params[:documents].map do |doc|
        record = record_class.new(attrs)
        record.working_user = current_user
        record.save
        record.store_archival_file(dsid, doc)
        record.save
        warnings << collect_warnings(record, dsid, doc)
        record
      end

      pids = records.map(&:pid)
      @batch.pids = (@batch.pids || []) + pids
      batch_saved = @batch.save

      flash[:alert] = warnings.join(', ') unless warnings.empty?

      respond_to do |format|
        format.html { redirect_to batch_path(@batch) }
        format.json {
          success = batch_saved && records.map(&:persisted?).all?
          if success
            redirect_to catalog_path(pids.first, 'json_format' => 'jquery-file-uploader')
          else
            json = { files: [
              { pid: records.first.id,
                name: records.first.title,
                error: collect_errors(records) }]
            }.to_json

            render json: json
          end
        }
      end

    else  # no documents have been passed in
      flash[:error] = "Please select some files to upload."
      render :edit
    end
  end

#  def handle_update_for_xml_import
#  end

end

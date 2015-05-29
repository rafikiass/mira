class BatchesController < ApplicationController
  load_and_authorize_resource only: :index
  before_filter :paginate, only: :index

  def index
    @batches = @batches.order(created_at: :desc)
  end

  def new_template_import
    @batch = BatchTemplateImport.new
  end

  def create
    require_pids_and_run_batch
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

private

  def paginate
    @batches = @batches.order('created_at DESC').page(params[:page]).per(10)
  end

  def create_and_run_batch
    @batch.creator = current_user

    if @batch.save
      if run_batch
        redirect_to @batch
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
    BatchRunnerService.new(@batch).run
  end

  def render_new_or_redirect
    redirect_to (request.referer || root_path)
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

  def collect_errors(batch, records)
    (batch.errors.full_messages + records.map{|r| r.errors.full_messages }.flatten).compact
  end

  def respond_to_import(successful, batch, document_statuses)
    docs, records, warnings, errors = document_statuses.transpose.map(&:compact)
    respond_to do |format|
      format.html do
        flash[:alert] = (warnings + errors).join(', ')
        if successful
          redirect_to @batch
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

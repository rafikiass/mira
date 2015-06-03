class BatchesController < ApplicationController
  load_and_authorize_resource only: :index
  before_filter :paginate, only: :index

  helper_method :resource

  def index
    @batches = @batches.order(created_at: :desc)
  end

  def create
    if resource.pids.present?
      create_and_run_batch
    else
      no_pids_selected
    end
  end

  def show
    @batch = BatchPresenter.new(@batch)
  end

  protected

    def resource
      @batch
    end

private

  def paginate
    @batches = @batches.order('created_at DESC').page(params[:page]).per(10)
  end

  def create_and_run_batch
    resource.creator = current_user

    if resource.save
      if run_batch
        redirect_to resource
      else
        flash[:error] = "Unable to run batch, please try again later."
        resource.delete
        reinit_resource
        render_new_or_redirect
      end
    else
      render_new_or_redirect  # form errors
    end
  end

  def reinit_resource
    @batch = Batch.new resource.attributes.except('id')
  end

  def run_batch
    BatchRunnerService.new(resource).run
  end

  def render_new_or_redirect
    redirect_to (request.referer || root_path)
  end

  def no_pids_selected
    flash[:error] = 'Please select some records to do batch updates.'
    redirect_to (request.referer || root_path)
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
          redirect_to resource
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

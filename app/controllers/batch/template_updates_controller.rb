class Batch::TemplateUpdatesController < BatchesController
  before_filter :build_batch, only: :create
  load_resource only: [:show, :edit], instance_name: :batch, class: 'BatchTemplateUpdate'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchTemplateUpdate', except: :new

  def new
    if params[:pids].blank?
      no_pids_selected
    else
      @batch = BatchTemplateUpdate.new(pids: params[:pids])
    end
  end

  def create
    if !@batch.pids.present?
      no_pids_selected
    else
      create_and_run_batch
    end
  end

  protected

  def run_batch
    BatchTemplateUpdateRunnerService.new(@batch).run
  end

  # Called by create_and_run_batch
  def render_new_or_redirect
    render :new
  end

  def build_batch
    @batch = BatchTemplateUpdate.new(params.require(:batch_template_update).permit(:template_id, { pids: [] }, :record_type, :metadata_file, :behavior))
  end

  def load_batch
    @batch = BatchTemplateUpdate.lock.find(params.require(:id))
  end
end

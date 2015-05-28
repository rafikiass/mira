class Batch::TemplateImportsController < BatchesController
  before_filter :build_batch, only: :create
  load_resource only: [:new, :show, :edit], instance_name: :batch, class: 'BatchTemplateImport'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchTemplateImport', except: :new

  def new
    @batch = BatchTemplateImport.new
  end

  def create
    @batch.creator = current_user

    if @batch.save
      redirect_to [:edit, @batch]
    else
      render :new
    end
  end

  def update
    if params[:documents].blank?
      # no documents have been passed in
      flash[:error] = "Please select some files to upload."
      render :edit
    else
      action = TemplateImportAction.new(@batch, current_user, params[:documents])
      respond_to_import(action.run, @batch, action.document_statuses)
    end
  end

  private

    def build_batch
      @batch = BatchTemplateImport.new(params.require(:batch).permit(:template_id, {pids: []}, :type, :record_type, :behavior))
    end

    def load_batch
      @batch = BatchTemplateImport.lock.find(params.require(:id))
    end
end

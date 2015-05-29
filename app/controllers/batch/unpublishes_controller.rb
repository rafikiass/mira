class Batch::UnpublishesController < BatchesController
  before_filter :build_batch, only: :create
  load_resource only: [:new, :show, :edit], instance_name: :batch, class: 'BatchUnpublish'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchUnpublish', except: :new

private

  def build_batch
    @batch = BatchUnpublish.new(pids: params[:pids])
  end

  def load_batch
    @batch = BatchUnpublish.lock.find(params.require(:id))
  end
end

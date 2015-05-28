class Batch::RevertsController < BatchesController
  before_filter :build_batch, only: :create
  load_resource only: [:new, :show, :edit], instance_name: :batch, class: 'BatchRevert'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchRevert', except: :new

private

  def build_batch
    @batch = BatchRevert.new(pids: params[:pids])
  end

  def load_batch
    @batch = BatchRevert.lock.find(params.require(:id))
  end
end

class Batch::PurgesController < BatchesController
  before_filter :build_batch, only: :create
  load_resource only: [:new, :show, :edit], instance_name: :batch, class: 'BatchPurge'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchPurge', except: :new


private

  def build_batch
    @batch = BatchPurge.new(pids: params[:pids])
  end

  def load_batch
    @batch = BatchPurge.lock.find(params.require(:id))
  end

end

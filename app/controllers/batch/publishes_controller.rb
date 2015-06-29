class Batch::PublishesController < BatchesController
  before_filter :build_batch, only: :create
  load_resource only: [:new, :show, :edit], instance_name: :batch, class: 'BatchPublish'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchPublish', except: :new

private

  def build_batch
    @batch = BatchPublish.new(pids: unique_pids)
  end

  def load_batch
    @batch = BatchPublish.lock.find(params.require(:id))
  end

end

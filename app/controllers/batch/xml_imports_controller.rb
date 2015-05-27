class Batch::XmlImportsController < ApplicationController
  before_filter :build_batch, only: :create
  load_resource only: [:new, :show, :edit], instance_name: :batch, class: 'BatchXmlImport'
  before_filter :load_batch, only: :update
  authorize_resource instance_name: :batch, class: 'BatchXmlImport', except: :new

  def new
    @batch = BatchXmlImport.new
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

  def update
    if params[:documents].blank?
      # no documents have been passed in
      flash[:error] = "Please select some files to upload."
      render :edit
      return
    end
    action = XmlBatchImportAction.new(@batch, current_user, params[:documents])
    success = action.run
    docs, records, warnings, errors = action.document_statuses.transpose.map(&:compact)
    respond_to do |format|
      format.html do
        flash[:alert] = (warnings + errors).join(', ')
        if success
          redirect_to batch_xml_import_path(@batch)
        else
          render :edit
        end
      end

      format.json do
        render json: json_response(action.document_statuses, records)
      end
    end
  end

  def create
    @batch.creator = current_user

    if @batch.save
      redirect_to edit_batch_xml_import_path(@batch)
    else
      render :new
    end
  end

  def edit
    if @batch.metadata_file.present?
      parser = MetadataXmlParser.new(@batch.metadata_file.read)
      @pids_that_already_exist = parser.pids.select {|pid| ActiveFedora::Base.exists?(pid)}
    end
  end

  private

  def build_batch
    @batch = BatchXmlImport.new(params.require(:batch_xml_import).permit(:template_id, { pids: [] }, :record_type, :metadata_file, :behavior))
  end

  def load_batch
    @batch = BatchXmlImport.lock.find(params.require(:id))
  end

  # TODO this is common with BatchesController
  def json_response(document_statuses, records)
    {
      files: document_statuses.map do |filename, record, warning, error|
        msg = {}
        if record.present?
          msg[:pid] = record.id
          msg[:title] = record.title
        end
        msg[:name] = filename
        msg[:warning] = warning if warning.present?
        errors = collect_errors(@batch, records)
        errors << error if error.present?
        msg[:error] = errors unless errors.empty?
        msg
      end
    }.to_json
  end

  # TODO this is common with BatchesController
  def collect_errors(batch, records)
    (batch.errors.full_messages + records.map{|r| r.errors.full_messages }.flatten).compact
  end

end

class Batch::MetadataImportsController < BatchesController
  load_and_authorize_resource

  def new
  end

  def show
    @metadata_import = BatchPresenter.new(@metadata_import)
  end

  def create
    parser = MetadataImportParser.new(resource.metadata_file)
    # sanity check
    if parser.valid?
      resource.pids = parser.pids
      create_and_run_batch
    else
      flash[:error] = parser.errors.join(', ')
      render :new
    end
  end

  protected

    def resource
      @metadata_import
    end

    def reinit_resource
      @metadata_import = Batch::MetadataImport.new(resource.attributes.except('id'))
    end

    def metadata_import_params
      params.require(:batch_metadata_import).permit(:metadata_file).tap do |clean_params|
        clean_params[:metadata_file] = clean_params[:metadata_file].read
      end
    end


end

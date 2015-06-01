class Batch::MetadataImportsController < BatchesController
  load_and_authorize_resource

  def new
  end

  def create
    doc = Nokogiri::XML.parse(resource.metadata_file)
    resource.pids = doc.xpath('//items/digitalObject/pid').map(&:content)
    create_and_run_batch
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

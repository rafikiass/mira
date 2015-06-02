class DownloadsController < ApplicationController
  include Hydra::Controller::DownloadBehavior

  def render_404
    respond_to do |format|
      format.any  { send_file 'app/assets/images/nope.png', disposition: 'inline', type: 'image/png' }
    end
  end

  def send_content
    if asset.is_a? TuftsGenericObject
      url = datastream.item(params[:offset].to_i).link
      local_path = url.first.sub(Settings.trim_bucket_url, Settings.object_store_root)
      logger.info("downloading #{local_path}")
      send_file(local_path)
    else
      send_file asset.local_path_for(params[:datastream_id]), content_options
    end
  end

  # Create some headers for the datastream
  def content_options
    {disposition: 'inline', type: datastream.mimeType, filename: datastream_name}
  end

  def datastream_name
    File.basename(asset.local_path_for(params[:datastream_id]))
  end

  def datastream_to_show
    if asset.is_a? TuftsGenericObject
      asset.datastreams['GENERIC-CONTENT']
    else
      super
    end
  end
end

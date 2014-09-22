module ThumbnailHelper

  # Displays the thumbnail image for the object
  # @param [SolrDocument, ActiveFedora::Base] document
  # @param [Hash] image_options
  # @option image_options :datastream_id ('Thumbnail.png') the datastream to draw
  def thumbnail_tag(document, image_options={})
    image_options = { datastream_id: 'Thumbnail.png' }.merge(image_options)
    if is_a(document, TuftsImage)
      url = thumbnail_url(document, image_options)
      image_tag url
    elsif is_a(document, CuratedCollection)
      image_tag thumbnail_url(document, image_options)
    else
      content_tag :span, '', class: 'canonical-image'
    end
  end

  def thumbnail_url(document, image_options={})
    # we use Basic as the default here for the blacklight-gallery slideshow
    image_options = { datastream_id: 'Basic.jpg' }.merge(image_options)
    if is_a(document, TuftsImage)
      download_path(document.id, datastream_id: image_options[:datastream_id])
    elsif is_a(document, CuratedCollection)
      'folder_thumbnail.png'
    end
  end

  private

  # Checks to see if this SolrDocument or model inherits from a given class
  def is_a(document, klass)
    if document.is_a? SolrDocument
      document['active_fedora_model_ssi'].constantize.ancestors.include? klass
    else
      document.is_a? klass
    end
  end
end


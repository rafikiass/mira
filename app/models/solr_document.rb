# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document
  include Tufts::SolrDocument

  def workflow_status
    if published?
      :published
    elsif published_at.blank?
      :unpublished
    else
      :edited
    end
  end

  def draft?
    self.fetch('id').start_with?('draft')
  end

  def published_at
    self[Solrizer.solr_name("published_at", :stored_sortable, type: :date)]
  end

  def has_datastream_content?(dsid)
    return unless self['object_profile_ssm']
    json = JSON.parse(Array(self['object_profile_ssm']).first)
    datastreams = json.fetch('datastreams', {})
    !datastreams.fetch(dsid, {}).empty?
  end

  # Link to the draft object in DL
  def preview_dl_path
    dl_path(PidUtils.to_draft(id))
  end

  def transfer_binary_filename
    begin
      json = JSON.parse(self['object_profile_ssm'].first)
      json['datastreams']['Transfer.binary']['dsLabel']
    rescue
      "Transfer.binary"
    end
  end

  # Link to the published object in DL
  def show_dl_path
    dl_path(PidUtils.to_published(id))
  end

private

  def dl_path(pid)
    return nil if template?
    displays = Array(self['displays_ssim'])
    if displays.include?('dl') || displays.all?{|x| x.blank? }
      Settings.preview_dl_url + "/catalog/#{pid}"
    end
  end

end

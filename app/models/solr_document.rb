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

end

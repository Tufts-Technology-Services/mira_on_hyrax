# frozen_string_literal: true
# Override Hyrax CollectionPresenter with a local version that adds the Call Number and Finding Aid fields
module Hyrax
  class TuftsCollectionPresenter < CollectionPresenter
    delegate :call_number, :finding_aid, to: :solr_document

    def nested_collection_pathnames
      solr_document['nesting_collection__pathnames_ssim']
    end

    # rubocop:disable Metrics/MethodLength
    def nested_collection_names_and_links
      cols = nested_collection_pathnames
      list_of_lists = []
      enhanced_id_list = []
      cols.each do |col|
        parsed_ids = col.split('/')
        parsed_ids.delete(id)
        enhanced_id_list = []
        parsed_ids.each do |p_id|
          results = Hyrax::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query(id: p_id), rows: 1, fl: 'title_tesim')
          title_tesim = results[0]['title_tesim']
          enhanced_id_list.push(id: p_id, title: title_tesim[0])
        end
        list_of_lists << enhanced_id_list
      end
      list_of_lists
    end

    def self.terms
      Hyrax::CollectionPresenter.terms + [:call_number, :finding_aid]
    end
  end
end

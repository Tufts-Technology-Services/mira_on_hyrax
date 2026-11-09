# frozen_string_literal: true
module Hyrax
  # Responsible for adding the necessary callbacks for updating the nested collection information
  # This is part of the after update index because it is a potentially very expensive process.
  #
  # @todo Consider extracting the update_index callback to ActiveFedora::Base
  # rubocop:disable Metrics/BlockLength
  module CollectionNesting
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :update_index, only: :after
      after_update_index :update_nested_collection_relationship_indices
      after_destroy :update_child_nested_collection_relationship_indices
      before_save :before_update_nested_collection_relationship_indices
      after_save :after_update_nested_collection_relationship_indices

      def before_update_nested_collection_relationship_indices
        @during_save = true
      end

      def after_update_nested_collection_relationship_indices
        @during_save = false
        index_current_nested_relationship_document
        enqueue_nested_relationship_reindex_for(id: id, extent: reindex_extent)
        # rubocop:disable Style/GuardClause
        if self.class.to_s == "Collection"
          children = find_children_of(destroyed_id: id)
          ids = []
          children.each do |child|
            ids << child.id
          end

          enqueue_child_nested_relationship_reindex_for(ids)
        end
      end

      def update_nested_collection_relationship_indices
        return if @during_save
        reindex_nested_relationships_for(id: id, extent: reindex_extent)
      end

      def update_child_nested_collection_relationship_indices
        children = find_children_of(destroyed_id: id)
        # puts children.to_s
        children.each do |child|
          # puts child.id.to_s
          reindex_nested_relationships_for(id: child.id, extent: Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
        end
      end
    end

    def update_index(*args)
      _run_update_index_callbacks { super }
    end

    def find_children_of(destroyed_id:)
      ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query(member_of_collection_ids_ssim: destroyed_id), rows: 500_000)
    end

    # Only models which include Hyrax::CollectionNesting will respond to this method.
    # Used to determine whether a model gets reindexed via Samvera::NestingIndexer during full repository reindexing,
    def use_nested_reindexing?
      true
    end

    # The following methods allow an option to reindex an object only if the nesting indexer fields are not
    # already in the object's solr document. Added to prevent unnecessary indexing of all ancestors of a parent
    # when one child gets added to the parent. By default, we do the full graph indexing.
    def reindex_extent
      @reindex_extent ||= Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
    end

    def reindex_extent=(val)
      @reindex_extent = val
    end

    private

    # to_solr does not include the nesting indexer fields, and SolrService.add replaces the whole
    # document. Carry the existing nesting fields forward so they aren't wiped while
    # NestedRelationshipReindexJob is pending (Hyrax reads deepest_nested_depth when nesting collections).
    def index_current_nested_relationship_document
      ActiveFedora::SolrService.add(existing_nesting_fields.merge(to_solr), commit: true)
    end

    def existing_nesting_fields
      fields = nesting_solr_field_names
      doc = ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id]),
                                            fl: fields.join(','), rows: 1).first
      return {} if doc.nil?
      doc.to_h.slice(*fields)
    end

    def nesting_solr_field_names
      config = Samvera::NestingIndexer.configuration
      [config.solr_field_name_for_storing_parent_ids,
       config.solr_field_name_for_storing_ancestors,
       config.solr_field_name_for_storing_pathnames,
       config.solr_field_name_for_deepest_nested_depth]
    end

    def enqueue_nested_relationship_reindex_for(id:, extent:)
      NestedRelationshipReindexJob.perform_later(id, extent)
    rescue ActiveJob::Uniqueness::JobNotUnique
      Rails.logger.warn "Tried to queue non-unique NestedRelationshipReindex job for #{id}"
    end

    def enqueue_child_nested_relationship_reindex_for(ids)
      ids.each_slice(IndexChildrenJob::BATCH_SIZE) do |child_ids|
        IndexChildrenJob.perform_later(child_ids)
      rescue ActiveJob::Uniqueness::JobNotUnique
        Rails.logger.warn "Tried to queue non-unique IndexChildren job for #{child_ids}"
      end
    end

    def reindex_nested_relationships_for(id:, extent:)
      Hyrax.config.nested_relationship_reindexer.call(id: id, extent: extent)
    end
  end
end

# frozen_string_literal: true
##
# Reindexes nested collection relationship fields outside the request cycle.
class NestedRelationshipReindexJob < ApplicationJob
  unique :until_executed

  queue_as :collection_indexer

  def perform(id, extent)
    Hyrax.config.nested_relationship_reindexer.call(id: id, extent: extent)
  end
end

# frozen_string_literal: true
##
# A job to register handles and save it to the object.
#
# @example
#   object = Pdf.create(title: ['Moomin'])
#   HandleRegisterJob.perform_later(object)
#
# @see ActiveJob::Base, HandleDispatcher.assign_for!
class IndexChildrenJob < ApplicationJob
  BATCH_SIZE = 100
  class ChildReindexError < StandardError; end

  unique :until_executed

  queue_as :collection_indexer

  ##
  def perform(children)
    failed_children = []

    children.each do |child|
      reindex_nested_relationships_for(id: child, extent: Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
    rescue StandardError => error
      failed_children << child
      Rails.logger.error "Failed to reindex child #{child}: #{error.class}: #{error.message}"
    end

    return if failed_children.empty?

    raise ChildReindexError, "Failed to reindex #{failed_children.size} children: #{failed_children.join(', ')}"
  end

  private

  def reindex_nested_relationships_for(id:, extent:)
    Hyrax.config.nested_relationship_reindexer.call(id: id, extent: extent)
  end
end

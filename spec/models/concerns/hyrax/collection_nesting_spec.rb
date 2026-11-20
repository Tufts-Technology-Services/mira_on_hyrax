# frozen_string_literal: true
# rubocop:disable RSpec/ExampleLength
require 'rails_helper'

RSpec.describe Hyrax::CollectionNesting do
  subject(:record) { test_class.new(id: id) }

  let(:id) { SecureRandom.uuid }
  let(:test_class) do
    Class.new do
      extend ActiveModel::Callbacks
      define_model_callbacks :save, :destroy
      include Hyrax::CollectionNesting

      attr_reader :id

      def initialize(id:)
        @id = id
      end

      def save
        _run_save_callbacks { true }
      end

      def to_solr
        { 'id' => id }
      end
    end
  end

  before do
    stub_const('CollectionNestingSpecModel', test_class)
    ActiveJob::Base.queue_adapter = :test
    allow(ActiveFedora::SolrService).to receive(:add)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
  end

  describe 'after save' do
    it 'indexes the current object inline' do
      allow(NestedRelationshipReindexJob).to receive(:perform_later)

      record.after_update_nested_collection_relationship_indices

      expect(ActiveFedora::SolrService)
        .to have_received(:add)
        .with({ 'id' => id }, commit: true)
    end

    it 'preserves existing nesting fields so they are not wiped before the reindex job runs' do
      allow(NestedRelationshipReindexJob).to receive(:perform_later)
      nesting_fields = {
        'nesting_collection__parent_ids_ssim' => ['parent'],
        'nesting_collection__ancestors_ssim' => ['parent'],
        'nesting_collection__pathnames_ssim' => ["parent/#{id}"],
        'nesting_collection__deepest_nested_depth_isi' => 2
      }
      allow(ActiveFedora::SolrService).to receive(:query).and_return([nesting_fields.merge('id' => 'stale')])

      record.after_update_nested_collection_relationship_indices

      expect(ActiveFedora::SolrService)
        .to have_received(:add)
        .with(nesting_fields.merge('id' => id), commit: true)
    end

    it 'queues nested relationship reindexing' do
      allow(NestedRelationshipReindexJob).to receive(:perform_later)

      record.after_update_nested_collection_relationship_indices

      expect(NestedRelationshipReindexJob)
        .to have_received(:perform_later)
        .with(id, Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
    end

    it 'does not run nested relationship reindexing inline' do
      allow(NestedRelationshipReindexJob).to receive(:perform_later)
      expect(Hyrax.config.nested_relationship_reindexer).not_to receive(:call)

      record.after_update_nested_collection_relationship_indices
    end
  end

  describe '#enqueue_child_nested_relationship_reindex_for' do
    it 'queues child reindexing in bounded batches' do
      ids = Array.new(IndexChildrenJob::BATCH_SIZE + 1) { |index| "child-#{index}" }
      allow(IndexChildrenJob).to receive(:perform_later)

      record.send(:enqueue_child_nested_relationship_reindex_for, ids)

      expect(IndexChildrenJob).to have_received(:perform_later).twice
      expect(IndexChildrenJob)
        .to have_received(:perform_later)
        .with(ids.first(IndexChildrenJob::BATCH_SIZE))
      expect(IndexChildrenJob)
        .to have_received(:perform_later)
        .with([ids.last])
    end
  end
end
# rubocop:enable RSpec/ExampleLength

# frozen_string_literal: true
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
    end
  end

  before do
    stub_const('CollectionNestingSpecModel', test_class)
    ActiveJob::Base.queue_adapter = :test
  end

  describe 'after save' do
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
end

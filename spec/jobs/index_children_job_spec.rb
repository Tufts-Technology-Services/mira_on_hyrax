# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IndexChildrenJob, type: :job do
  subject(:job) { described_class }

  let(:reindexer) { instance_double('NestedRelationshipReindexer') }

  before do
    allow(Hyrax.config).to receive(:nested_relationship_reindexer).and_return(reindexer)
    allow(reindexer).to receive(:call)
  end

  describe '.queue_name' do
    it 'uses the collection indexer queue' do
      expect(job.queue_name).to eq 'collection_indexer'
    end
  end

  describe '#perform' do
    it 'runs the nested relationship reindexer for each child' do
      described_class.new.perform(%w[child-1 child-2])

      expect(reindexer)
        .to have_received(:call)
        .with(id: 'child-1', extent: Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
      expect(reindexer)
        .to have_received(:call)
        .with(id: 'child-2', extent: Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
    end

    it 'continues reindexing later children when one child fails' do
      allow(Rails.logger).to receive(:error)
      allow(reindexer).to receive(:call) do |id:, **|
        raise StandardError, 'failed' if id == 'child-1'
      end

      expect { described_class.new.perform(%w[child-1 child-2]) }
        .to raise_error(IndexChildrenJob::ChildReindexError, /child-1/)

      expect(reindexer)
        .to have_received(:call)
        .with(id: 'child-2', extent: Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
      expect(Rails.logger)
        .to have_received(:error)
        .with('Failed to reindex child child-1: StandardError: failed')
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe NestedRelationshipReindexJob, type: :job do
  subject(:job) { described_class }

  let(:extent) { Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX }
  let(:id) { SecureRandom.uuid }
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
    it 'runs the nested relationship reindexer' do
      described_class.new.perform(id, extent)

      expect(reindexer).to have_received(:call).with(id: id, extent: extent)
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AttachTypedFilesToWorkJob, type: :job do
  subject(:job) { described_class.new }

  let(:user) { FactoryBot.create(:user) }
  let(:work) do
    instance_double(Pdf,
                    depositor: user.user_key,
                    permissions: [],
                    visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end

  describe '#perform' do
    context 'when an uploaded file already has a file set URI' do
      let(:uploaded_file) { FactoryBot.create(:hyrax_uploaded_file, file_set_uri: 'file_set_uri') }

      it 'does not create another file set' do
        expect(FileSet).not_to receive(:create)

        job.perform(work, [uploaded_file])
      end
    end

    context 'with new uploaded files' do
      let(:uploaded_file) { FactoryBot.create(:hyrax_uploaded_file) }
      let(:file_set) { instance_double(FileSet, uri: 'new_file_set_uri') }
      let(:actor) do
        instance_double(Hyrax::Actors::FileSetActor,
                        file_set: file_set,
                        create_metadata: true,
                        create_content: true,
                        attach_to_work: true)
      end

      before do
        allow(file_set).to receive(:permissions_attributes=)
        allow(FileSet).to receive(:create).and_return(file_set)
        allow(Hyrax::Actors::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)
      end

      it 'marks the upload with its file set URI before attaching it to the work' do
        job.perform(work, [uploaded_file])

        expect(uploaded_file.reload.file_set_uri).to eq 'new_file_set_uri'
        expect(actor).to have_received(:attach_to_work).with(work)
      end
    end
  end
end

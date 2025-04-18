# frozen_string_literal: true
module Hyrax
  module Actors
    # Creates a work and attaches files to the work,
    # passes types through to the attach files job
    class CreateWithFilesAndPassTypesActor < CreateWithFilesActor
      def create(env)
        @thumbnail      = env.attributes.delete(:thumbnail)
        @transcript     = env.attributes.delete(:transcript)
        @representative = env.attributes.delete(:representative)
        super
      end

      def attach_files(files, curation_concern, attributes)
        return true if files.blank?
        attributes = attributes.merge(file_type_attributes)
        # TODO: see if AttachTypedFilesToWorkJob needs touch ups
        AttachTypedFilesToWorkJob.perform_later(curation_concern, files, attributes.to_h.symbolize_keys)
        true
      end

      def file_type_attributes
        types = {}
        types[:thumbnail]      = @thumbnail      if @thumbnail.present?
        types[:transcript]     = @transcript     if @transcript.present?
        types[:representative] = @representative if @representative.present?
        types
      end
    end
  end
end

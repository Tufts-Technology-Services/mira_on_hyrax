# frozen_string_literal: true
module Tufts
  module HasTranscriptForm
    # SRT files are typically characterized as text/plain or application/x-subrip
    VIDEO_TRANSCRIPT_MIME_TYPES = ['xml', 'plain', 'vtt', 'subrip'].freeze
    AUDIO_TRANSCRIPT_MIME_TYPES = ['xml', 'plain', 'subrip'].freeze

    def transcript_files(type)
      transcript_files = file_presenters.select { |file| transcript?(file, type) }
      Hash[transcript_files.map { |file| [file.to_s, file.id] }]
    end

    def transcript?(file, object_type)
      mime_types = if object_type == "Video" || object_type == "Generic Object"
                     VIDEO_TRANSCRIPT_MIME_TYPES
                   else
                     AUDIO_TRANSCRIPT_MIME_TYPES
                   end
      mime_types.any? { |mime_type| file.mime_type&.include?(mime_type) }
    end
  end
end

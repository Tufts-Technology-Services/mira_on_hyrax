# frozen_string_literal: true

require_dependency Hyrax::Engine.root.join('app', 'jobs', 'create_derivatives_job').to_s

class CreateDerivativesJob
  # Temporary debug wrapper around Hyrax's derivative job.
  # Enable with DERIVATIVE_DEBUG=1 on the worker process.
  def perform(file_set, file_id, filepath = nil)
    derivative_debug("job start file_set_id=#{file_set.id} file_id=#{file_id.inspect} filepath=#{filepath.inspect} filepath_exists=#{filepath && File.exist?(filepath)} mime_type=#{file_set.mime_type.inspect}")
    return if file_set.video? && !Hyrax.config.enable_ffmpeg

    derivative_debug("before find_or_retrieve")
    filename = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id, filepath)
    derivative_debug("after find_or_retrieve filename=#{filename.inspect} exists=#{File.exist?(filename)} size=#{file_size(filename)}")

    derivative_debug("before create_derivatives")
    file_set.create_derivatives(filename)
    derivative_debug("after create_derivatives")

    derivative_debug("before file_set.reload")
    file_set.reload
    derivative_debug("after file_set.reload")

    derivative_debug("before file_set.update_index")
    file_set.update_index
    derivative_debug("after file_set.update_index")

    if parent_needs_reindex?(file_set)
      derivative_debug("before parent.update_index parent_id=#{file_set.parent.id}")
      file_set.parent.update_index
      derivative_debug("after parent.update_index")
    else
      derivative_debug("parent reindex skipped")
    end

    derivative_debug("job complete")
  end

  private

  def derivative_debug(message)
    Rails.logger.info("[DERIVATIVE_DEBUG] #{message}") if ENV['DERIVATIVE_DEBUG'] == '1'
  end

  def file_size(path)
    File.exist?(path) ? File.size(path) : 'missing'
  end
end

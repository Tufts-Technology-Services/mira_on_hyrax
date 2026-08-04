# frozen_string_literal: true
require 'tmpdir'
require 'open3'

# Patching execute_without_timeout to handle IO:EAGAINWaitReadable appropriately:
# https://apidock.com/ruby/IO/read_nonblock
# This was throwing an exception in sidekiq when processing videos.
module Hydra::Derivatives::Processors
  module ShellBasedProcessor
    extend ActiveSupport::Concern

    BLOCK_SIZE = 1024

    included do
      class_attribute :timeout
      extend Open3
    end

    def process
      format = directives[:format]
      raise ArgumentError, "You must provide the :format you want to transcode into. You provided #{directives}" unless format
      # TODO: if the source is in the correct format, we could just copy it and skip transcoding.
      encode_file(format, options_for(format))
    end

    # override this method in subclass if you want to provide specific options.
    # returns a hash of options that the specific processors use
    def options_for(_format)
      {}
    end

    def encode_file(file_suffix, options)
      temp_file_name = output_file(file_suffix)
      derivative_debug("encode_file start format=#{file_suffix} source_path=#{source_path.inspect} source_exists=#{File.exist?(source_path)} temp_file=#{temp_file_name.inspect} directives=#{directives.inspect} options=#{options.inspect}")
      self.class.encode(source_path, options, temp_file_name)
      derivative_debug("ffmpeg complete temp_file=#{temp_file_name.inspect} temp_exists=#{File.exist?(temp_file_name)} temp_size=#{file_size(temp_file_name)}")
      output_file_service.call(File.open(temp_file_name, 'rb'), directives)
      derivative_debug("output_file_service complete url=#{directives[:url].inspect}")
      File.unlink(temp_file_name)
      derivative_debug("temp_file removed temp_file=#{temp_file_name.inspect}")
    end

    def output_file(file_suffix)
      Dir::Tmpname.create(['sufia', ".#{file_suffix}"], Hydra::Derivatives.temp_file_base) {}
    end

    def derivative_debug(message)
      Rails.logger.info("[DERIVATIVE_DEBUG] #{message}") 
    end

    def file_size(path)
      File.exist?(path) ? File.size(path) : 'missing'
    end

    module ClassMethods
      def execute(command)
        context = {}
        if timeout
          execute_with_timeout(timeout, command, context)
        else
          execute_without_timeout(command, context)
        end
      end

      def execute_with_timeout(timeout, command, context)
        Timeout.timeout(timeout) do
          execute_without_timeout(command, context)
        end
      rescue Timeout::Error
        pid = context[:pid]
        Process.kill("KILL", pid)
        raise Hydra::Derivatives::TimeoutError, "Unable to execute command \"#{command}\"\nThe command took longer than #{timeout} seconds to execute"
      end

      def execute_without_timeout(command, context) # rubocop:disable Metrics/MethodLength
        err_str = "".dup
        derivative_debug("command=#{command}")
        stdin, stdout, stderr, wait_thr = popen3(command)
        context[:pid] = wait_thr[:pid]
        derivative_debug("pid=#{context[:pid]}")
        files = [stderr, stdout]
        stdin.close

        until all_eof?(files)
          ready = IO.select(files, nil, nil, 60)

          next unless ready
          readable = ready[0]
          readable.each do |f|
            fileno = f.fileno

            begin
              data = f.read_nonblock(BLOCK_SIZE)

              case fileno
              when stderr.fileno
                err_str << data
              end
            rescue EOFError
              Hydra::Derivatives::Logger.debug "Caught an eof error in ShellBasedProcessor"
              # No big deal.
            rescue IO::EAGAINWaitReadable
              IO.select([f])
              retry
            end
          end
        end

        stdout.close
        stderr.close
        exit_status = wait_thr.value
        derivative_debug("exit_status=#{exit_status}")

        raise "Unable to execute command \"#{command}\". Exit code: #{exit_status}\nError message: #{err_str}" unless exit_status.success?
      end

      def all_eof?(files)
        files.find { |f| !f.eof }.nil?
      end

      def derivative_debug(message)
        Rails.logger.info("[DERIVATIVE_DEBUG] #{message}") if ENV['DERIVATIVE_DEBUG'] == '1'
      end
    end
  end
end

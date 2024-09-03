# frozen_string_literal: true
module Hyrax
  class RepositoryFixityCheckService
    # This is a service that folks can use in their own rake tasks,
    # etc. It is not otherwise called or relied upon in Hyrax.
    # @see https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#fixity-checking
    def self.fixity_check_everything
      results = Hyrax::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query(has_model_ssim: "FileSet"), rows: 500_000, fl: 'id')
      ids = results.map { |o| o['id'] }
      ids.each do |fs|
        file_set = ::FileSet.find(fs)
        Hyrax::FileSetFixityCheckService.new(file_set).fixity_check
      rescue ActiveFedora::ObjectNotFoundError
        # no-op
        Rails.logger.info "#{fs} doesn't exist"
      rescue Ldp::Gone
        # no-op
        Rails.logger.info "#{fs} doesn't exist"
      end
    end

    def self.fixity_check_fileset(id)
      file_set = ::FileSet.find(id)
      Hyrax::FileSetFixityCheckService.new(file_set).fixity_check
    end

    def self.fixity_check_random_sampling
      # current count 174884
      results = Hyrax::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query(has_model_ssim: "FileSet"), rows: 500_000, fl: 'id')
      ids = results.map { |o| o['id'] }
      random_sample = ids.sample(2000)
      count = 0
      random_sample.each do |fs|
        count += 1
        Rails.logger.info "fixity count: #{count}"
        file_set = ::FileSet.find(fs)
        Hyrax::FileSetFixityCheckService.new(file_set).fixity_check
      end
    end
  end
end

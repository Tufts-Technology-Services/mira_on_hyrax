# frozen_string_literal: true
module Tufts
  # Create and maintain the Collection objects required by the Contribute controller
  # Note that the rake task that uses this class is called at the initialization of a new TDL environment.
  # It runs in production only once (e.g. Fedora 3 -> 4 migration), but it's useful in development environments
  # since they are recreated more frequently.

  class ContributeCollections
    attr_reader :seed_data

    def initialize
      @seed_data = make_seed_data_hash
    end

    def make_seed_data_hash
      SEED_DATA.index_by { |collection| collection[:id] }
    end

    def self.create
      Tufts::ContributeCollections.new.create
    end

    def create
      default = Hyrax::CollectionType.find_or_create_default_collection_type
      # admin_set = Hyrax::CollectionType.find_or_create_admin_set_type
      @seed_data.each_key do |data_id|
        find_or_create_collection(data_id, default)
      end
    end

    # Given a collection's call number, find or create the collection.
    # If the collection has been deleted, eradicate it so the id can be
    # re-used, and re-create the collection object.
    # @param [String] call_number
    # @return [Collection]
    def find_or_create_collection(data_id, default = nil)
      collection = find_collection(data_id)
      return collection if collection

      default ||= Hyrax::CollectionType.find_or_create_default_collection_type
      create_collection(data_id, default)
    end

    # @param [String] data_id
    # @return [Collection]
    def create_collection(data_id, default = Hyrax::CollectionType.find_or_create_default_collection_type)
      collection = Collection.new
      collection_hash = @seed_data[data_id]
      collection.title = Array(collection_hash[:title])
      collection.id = collection_hash[:id]
      collection.call_number = Array(collection_hash[:call_number]) if collection_hash.key?(:call_number)
      collection.finding_aid = Array(collection_hash[:finding_aid]) if collection_hash.key?(:finding_aid)
      collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      collection.collection_type = default
      collection.save
      collection
    end

    # Convenience method for use by the contribute controller
    # @param [Class] work_type
    # @return [Collection]
    # @example
    #  Tufts::ContributeCollections.collection_for_work_type(FacultyScholarship)
    def self.collection_for_work_type(work_type)
      Tufts::ContributeCollections.new.collection_for_work_type(work_type)
    end

    # For a given work type, determine which Collection contributions should go into.
    # If that collection object doesn't exist for some reason, create it.
    # @param [Class] work_type
    # @return [Collection]
    def collection_for_work_type(work_type)
      data_id = @seed_data.select { |_key, hash| hash[:work_types].include? work_type }.keys.first

      find_or_create_collection(data_id)
    end

    SEED_DATA = [
      {
        title: "Tufts Published Scholarship",
        id: "2j62s484w",
        call_number: "PB",
        finding_aid: "https://archives.tufts.edu/repositories/2/resources/100",
        work_types: [GenericDeposit, GenericTischDeposit, GisPoster, UndergradSummerScholar, FacultyScholarship]
      },
      {
        title: "Fletcher School Records",
        id: "0g354f20t",
        call_number: "UA015",
        finding_aid: "https://archives.tufts.edu/repositories/2/resources/120",
        work_types: [CapstoneProject]
      },
      {
        title: "Cummings School of Veterinary Medicine Records",
        id: "xd07gs68j",
        call_number: "UA041",
        finding_aid: "https://archives.tufts.edu/repositories/2/resources/4",
        work_types: [CummingsThesis]
      },
      {
        title: "Senior Honors Theses",
        id: "8910jt56k",
        call_number: "UA005",
        finding_aid: "https://archives.tufts.edu/repositories/2/resources/123",
        work_types: [HonorsThesis]
      },
      {
        title: "Public Health and Professional Degree Programs Records",
        id: "cz30q546w",
        call_number: "UA187",
        finding_aid: "https://archives.tufts.edu/repositories/2/resources/253",
        work_types: [PublicHealth]
      },
      {
        title: "Department of Education Records",
        id: "sq87bt605",
        call_number: "UA071",
        finding_aid: "https://archives.tufts.edu/repositories/2/resources/9",
        work_types: [QualifyingPaper]
      },
      {
        title: "Student Scholarship",
        id: "nk322d32h",
        work_types: [GradScholarship]
      }
    ].freeze

  private

    def find_collection(data_id)
      Collection.find(data_id)
    rescue ActiveFedora::ObjectNotFoundError
      nil
    end
  end
end

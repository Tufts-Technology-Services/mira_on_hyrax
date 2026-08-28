# frozen_string_literal: true
class Chronopolis::Exporter
  def initialize
    @logger = Logger.new('log/chronopolis.log')
  end

  def perform_export(pid, include_metadata = true)
    @logger.info "PROCESSING PID : #{pid}"
    obj = ActiveFedora::Base.find(pid)

    steward = steward_from_object(obj)
    collection = collection_from_object(obj)
    obj_dir = create_object_directory(obj, steward, collection)

    process_file_sets(obj, steward, collection, obj_dir, include_metadata)
    write_metadata(obj, steward, collection, obj_dir) if include_metadata

  rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
    @logger.error "ERROR: Pid not found #{pid}"
  end

  private

  def process_file_sets(obj, steward, collection, obj_dir, include_metadata)
    obj.file_sets.each do |file_set|
      process_file_set(file_set, steward, collection, obj_dir, include_metadata)
    end
  end

  def process_file_set(file_set, steward, collection, obj_dir, include_metadata)
    target_file, metadata_file = prepare_file_paths(file_set, steward, collection, obj_dir)

    write_file(file_set, target_file)
    write_metadata_file(file_set, metadata_file) if include_metadata
  end

  def write_file(file_set, target_file)
    File.open(target_file, 'wb') do |file|
      @logger.info "Writing fileset to #{target_file}"
      file.write(file_set.original_file.content)
    end
  rescue StandardError => e
    @logger.error "ERROR writing file: #{e.message}"
  end

  def write_metadata_file(file_set, metadata_file)
    metadata = JSON.pretty_generate(file_set.characterization_proxy.metadata.attributes)

    File.open(metadata_file, 'w') do |file|
      @logger.info "Writing metadata to #{metadata_file}"
      file.write(metadata)
    end
  rescue StandardError => e
    @logger.error "ERROR writing metadata: #{e.message}"
  end

  def prepare_file_paths(file_set, steward, collection, obj_dir)
    sanitized_name = sanitize_filename(file_set.id + "_" + file_set.title.first).truncate(255)
    target_dir = File.join('/', 'tdr', 'chronopolis', steward, collection, obj_dir, sanitized_name)
    FileUtils.mkdir_p(target_dir)

    mime_extension = file_set.mime_type&.split('/')&.last
    filename_with_extension = [sanitized_name, mime_extension].compact.join('.')
    target_file = validate_file_length(File.join(target_dir, filename_with_extension))
    metadata_file = File.join(target_dir, "technical_metadata.json")

    [target_file, metadata_file]
  end

  def validate_file_length(file_path)
    if file_path.length > 254
      random_string = SecureRandom.alphanumeric(10)
      @logger.error "File path too long: #{file_path.length} characters. Mapping to random string."
      File.join(File.dirname(file_path), random_string)
    else
      file_path
    end
  end

  def write_metadata(obj, steward, collection, obj_dir)
    metadata_file = File.join('/', 'tdr', 'chronopolis', steward, collection, obj_dir, "metadata.json")
    metadata = JSON.pretty_generate(obj.attributes)

    File.open(metadata_file, 'w') do |file|
      @logger.info "Writing metadata to #{metadata_file}"
      file.write(metadata)
    end
  rescue StandardError => e
    @logger.error "ERROR writing metadata: #{e.message}"
  end

  def create_object_directory(obj, steward, collection)
    obj_dir = sanitize_filename("#{obj.id}_#{obj.title.first}").truncate(255)
    obj_dir_path = File.join('/', 'tdr', 'chronopolis', steward, collection, obj_dir)
    FileUtils.mkdir_p(obj_dir_path)
    obj_dir
  end

  def collection_from_object(obj)
    collections = obj.member_of_collections
    return "uncollected" if collections.blank?

    prioritized_collection = prioritize_collection(collections)
    sanitize_filename("#{prioritized_collection.id}_#{prioritized_collection.title.first}").truncate(255)
  end

  def prioritize_collection(collections)
    priority_titles = ["Electronic Theses and Dissertations", "Collection Descriptions"]
    collections.find { |c| priority_titles.include?(c.title.first) } || collections.first
  end

  def steward_from_object(obj)
    steward = obj.steward.presence || "no_steward"
    @logger.info "Steward for #{obj.id} is #{steward}"
    sanitize_filename(steward)
  end

  def sanitize_filename(filename)
    filename.gsub(/[^a-z0-9\-_\.]/i, '_')
  end
end

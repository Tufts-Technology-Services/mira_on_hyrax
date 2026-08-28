# frozen_string_literal: true
require 'rake'

desc "chronopolis"
task :chronopolis_export_by_id, [:pid] => [:environment] do |_t, args|
  pid = args[:pid]
  if pid.blank?
    Rails.logger.error "PID is required for exporting."
    return
  end

  exporter = Chronopolis::Exporter.new
  exporter.perform_export(pid)
end

desc "chronopolis"
task chronopolis: :environment do
  exporter = Chronopolis::Exporter.new
  process_csv("/usr/local/samvera/epigaea/chronopolis.txt") do |pid|
    exporter.perform_export(pid)
  end
end

desc "chronopolis export of only binaries"
task chronopolis_binary_only: :environment do
  exporter = Chronopolis::Exporter.new
  process_csv("/usr/local/samvera/epigaea/chronopolis.txt") do |pid|
    exporter.perform_export(pid, false)
  end
end

desc 'Run an eDisMax query with parameters'
task :edismax_query, [:start_date] => :environment do |_t, args|
  args.with_defaults(start_date: '2023-06-01T00:00:00Z')
  exporter = Chronopolis::Exporter.new

  solr_url = ActiveFedora::SolrService.instance.conn.uri.to_s
  solr = RSolr.connect(url: solr_url)

  query_params = construct_main_query(args[:start_date])
  response = solr.get('select', params: query_params)
  Rails.logger.info "Query executed successfully!"

  ids = extract_ids_from_response(response)
  Rails.logger.info "Found #{ids.size} IDs to process."

  ids.each do |id|
    process_member_ids(solr, id, exporter)
  end
end

# Helper Methods

def process_csv(file_path)
  unless File.exist?(file_path)
    Rails.logger.error "File not found: #{file_path}"
    return
  end

  CSV.foreach(file_path, headers: false, header_converters: :symbol, encoding: "ISO8859-1:utf-8") do |row|
    pid = row[0]
    yield(pid) if block_given?
  end
end

def construct_main_query(start_date)
  {
    'q.alt': "{!term f=has_model_ssim}FileSet",
    fq: "system_modified_dtsi:[#{start_date} TO *]",
    rows: 1_000_000,
    fl: 'id',
    defType: 'edismax',
    wt: 'json'
  }
end

def extract_ids_from_response(response)
  response.dig('response', 'docs')&.map { |doc| doc['id'] } || []
end

# rubocop:disable Metrics/MethodLength
def process_member_ids(solr, id, exporter)
  member_query_params = {
    q: '*:*',
    fq: "member_ids_ssim:#{id}",
    fl: 'id',
    rows: 10,
    wt: 'json'
  }

  member_response = solr.get('select', params: member_query_params)
  member_ids = extract_ids_from_response(member_response)

  pid = member_ids.first
  if pid.present?
    Rails.logger.info "Exporting PID: #{pid}"
    exporter.perform_export(pid)
  else
    Rails.logger.warn "No members found for ID: #{id}"
  end
end
# rubocop:enable Metrics/MethodLength

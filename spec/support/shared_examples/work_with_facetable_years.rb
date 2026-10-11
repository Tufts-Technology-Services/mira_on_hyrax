# frozen_string_literal: true
RSpec.shared_examples 'a work with facetable years' do
  let(:indexer) { Tufts::Curation::Indexer.new(work) }
  let(:work) { described_class.new }

  it "indexes years in YYYY format" do
    work.primary_date = ["1835"]
    expect(work.to_solr['pub_date_facet_isim']).to include 1835
  end

  it "indexes dates with multiple values" do
    work.primary_date = ["1441", "2018"]
    expect(work.to_solr['pub_date_facet_isim']).to include 1441, 2018
  end

  it "indexes years in YYYY-MM-DD format" do
    work.temporal = ["1973-04-09"]
    expect(work.to_solr['pub_date_facet_isim']).to include 1973
  end

  it "indexes year ranges in the form YYYY-YYYY" do
    work.temporal = ["1910-1919"]
    expect(work.to_solr['pub_date_facet_isim']).to include 1910, 1915, 1919
  end

  it "indexes and deduplicates years" do
    work.temporal = ["1847-1850", "1848-1852"]
    expect(work.to_solr['pub_date_facet_isim']).to contain_exactly 1847, 1848, 1849, 1850, 1851, 1852
  end

  it "indexes mixed date values" do
    work.primary_date = ["1847-1850", "2018-02-06", "1848-1852", "1850-01-15", "1441"]
    expect(work.to_solr['pub_date_facet_isim']).to contain_exactly 1441, 1847, 1848, 1849, 1850, 1851, 1852, 2018
  end

  it "returns nil when the date is empty" do
    work.primary_date = nil
    expect(work.to_solr['pub_date_facet_isim']).to eq []
  end

  it "returns nil when the date contains 'n.d.'" do
    work.temporal = ["n.d."]
    expect(work.to_solr['pub_date_facet_isim']).to eq []
  end
end

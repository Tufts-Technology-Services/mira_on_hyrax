# frozen_string_literal: true
shared_examples 'has descriptive metadata attributes' do
  it 'has contributor' do
    work.contributor = ['Rovner, LIsa, film director, screenwriter']
    expect(work.resource.dump(:ttl))
      .to match(/contributor/)
  end

  it 'has creator' do
    work.creator = ['Dennett, D. C. (Daniel Clement)']
    expect(work.resource.dump(:ttl))
      .to match(/creator/)
  end

  it 'has date_uploaded' do
    work.date_uploaded = '10/28/21'
    expect(work.resource.dump(:ttl))
      .to match(/dateSubmitted/)
  end

  it 'has subject' do
    work.subject = ['Physics']
    expect(work.resource.dump(:ttl))
      .to match(/subject/)
  end

  it 'has publisher' do
    work.publisher = ['Penguin']
    expect(work.resource.dump(:ttl))
      .to match(/publisher/)
  end

  it 'has oclc' do
    work.oclc = ['677375104']
    expect(work.resource.dump(:ttl))
      .to match(/oclc/)
  end

  it 'has isbn' do
    work.isbn = ['9780790506395']
    expect(work.resource.dump(:ttl))
      .to match(/isbn/)
  end

  it 'has doi' do
    # TODO: doi figure out why it thinks the D should be apitalize now
    work.Doi = '387415'
    expect(work.resource.dump(:ttl))
      .to match(/doi/)
  end

  it 'has description' do
    work.description = ['A drawing of New Jersey governor James Florio with an incinerator in the background.']
    expect(work.resource.dump(:ttl))
      .to match(/description/)
  end

  it 'has geographic_names' do
    work.geographic_name = ['China']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/spatial/)
  end

  it 'has geog_names' do
    work.geog_name = ['China']
    expect(work.resource.dump(:ttl))
      .to match(/dl\.tufts\.edu\/terms\#geog_name/)
  end

  it 'has alternative_title' do
    work.alternative_title = ['An alternative title']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/alternative/)
  end

  it 'has abstract' do
    work.abstract = ['A descriptive abstract']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/abstract/)
  end

  it 'has table_of_contents' do
    work.table_of_contents = ['Chapter 1']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/tableOfContents/)
  end

  it 'has primary_date' do
    work.primary_date = ['12/31/99']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/elements\/1.1\/date/)
  end

  it 'has date_accepted' do
    work.date_accepted = ['01/01/00']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/dateAccepted/)
  end

  it 'has date_available' do
    work.date_available = ['01/02/00']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/available/)
  end

  it 'has date_copyrighted' do
    work.date_copyrighted = ['01/03/00']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/dateCopyrighted/)
  end

  it 'has date_issued' do
    work.date_issued = ['01/04/00']
    expect(work.resource.dump(:ttl))
      .to match(/ebu\.ch\/metadata\/ontologies\/ebucore\/ebucore#dateIssued/)
  end

  it 'has a resource_type' do
    work.resource_type = ['Collection']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/type/)
  end

  it 'has a bilographic_citation' do
    work.bibliographic_citation = ['Collection']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/bibliographicCitation/)
  end

  it 'has rights_holder' do
    work.rights_holder = ['Someone']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/rightsHolder/)
  end

  it 'has format_label' do
    work.format_label = ['a format label']
    expect(work.resource.dump(:ttl))
      .to match(/loc\.gov\/premis\/rdf\/v1#hasFormatName/)
  end

  it 'has replaces' do
    work.replaces = ['a replacement']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/replaces/)
  end

  it 'has is_replaced_by' do
    work.is_replaced_by = ['Something that is replaced by']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/isReplacedBy/)
  end

  it 'has has_part' do
    work.has_part = ['a part']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/hasPart/)
  end

  it 'has extent' do
    work.extent = ['12x12']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/extent/)
  end

  it 'has personal_name' do
    work.personal_name = ['Someone']
    expect(work.resource.dump(:ttl))
      .to match(/loc\.gov\/mads\/rdf\/v1#PersonalName/)
  end

  it 'has corporate_name' do
    work.corporate_name = ['Something']
    expect(work.resource.dump(:ttl))
      .to match(/loc\.gov\/mads\/rdf\/v1#CorporateName/)
  end

  it 'has genre' do
    work.genre = ['a genre']
    expect(work.resource.dump(:ttl))
      .to match(/loc\.gov\/mads\/rdf\/v1#GenreForm/)
  end

  it 'has provenance' do
    work.provenance = ['Someone']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/provenance/)
  end

  it 'has temporal' do
    work.temporal = ['20th century']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/temporal/)
  end

  it 'has dissertation_type' do
    work.dissertation_type = 'undergraduate'
    expect(work.resource.dump(:ttl))
      .to match(/id\.loc\.gov\/ontologies\/bibframe/)
  end

  it 'has funder' do
    work.funder = ['Viewers Like You']
    expect(work.resource.dump(:ttl))
      .to match(/id\.loc\.gov\/vocabulary\/relators/)
  end
end

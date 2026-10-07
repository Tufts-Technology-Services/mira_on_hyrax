# frozen_string_literal: true
shared_examples 'has admin metadata attributes' do
  describe '#mark_reviewed!' do
    it 'sets #reviewed?' do
      expect { work.mark_reviewed! }
        .to change { work.reviewed? }
        .from(false)
        .to(true)
    end
  end

  describe '#reviewed?' do
    before { work.qr_status = ['qr status'] }

    it 'is true when qr_status is set to "Batch Reviewed"' do
      expect { work.qr_status << 'Batch Reviewed' }
        .to change { work.reviewed? }
        .from(false)
        .to(true)
    end
  end

  it 'has admin_start_date' do
    work.admin_start_date = ['12/17/22']
    expect(work.resource.dump(:ttl))
      .to match(/startDate/)
  end

  it 'has aspace_cuid' do
    work.aspace_cuid = 'Identifier'
    expect(work.resource.dump(:ttl))
      .to match(/aspace_cuid/)
  end

  it 'has displays_in' do
    work.displays_in = ['nowhere', 'trove']
    expect(work.resource.dump(:ttl))
      .to match(/dl\.tufts\.edu\/terms\#displays_in/)
  end

  it 'has held_by' do
    work.held_by = ['United States']
    # TODO: make sure this chagne is fine
    expect(work.resource.dump(:ttl))
      .to match(/bibframe\/heldBy/)
  end

  it 'has steward' do
    work.steward = 'A steward'
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#steward/)
  end

  it 'has downloadable' do
    work.downloadable = 'no-link'
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#downloadable/)
  end

  it 'has internal_note' do
    work.internal_note = ['An internal note']
    expect(work.resource.dump(:ttl))
      .to match(/dl\.tufts\.edu\/terms#internal_note/)
  end

  it 'has audience' do
    work.audience = 'An audience'
    expect(work.resource.dump(:ttl)).to match(/purl\.org\/dc\/terms\/audience/)
  end

  it 'has an end_date' do
    work.end_date = '01/01/18'
    expect(work.resource.dump(:ttl))
      .to match(/loc\.gov\/premis\/rdf\/v1#hasEndDate/)
  end

  it 'has a embargo_note' do
    work.embargo_note = '01/01/18'
    expect(work.resource.dump(:ttl))
      .to match(/loc\.gov\/premis\/rdf\/v1#TermOfRestriction/)
  end

  it 'has an accrual_policy' do
    work.accrual_policy = 'an accrual policy'
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/accrualPolicy/)
  end

  it 'has rights_note' do
    work.rights_note = 'A note about TARC Detailed Rights'
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/elements\/1.1\/rights/)
  end

  it 'has legacy pid' do
    work.legacy_pid = 'atestpid'
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#legacy_pid/)
  end

  it 'has retention period' do
    work.retention_period = ['10 days']
    expect(work.resource.dump(:ttl))
      .to match(/dl\.tufts\.edu\/terms#retention_period/)
  end

  it 'has start_date' do
    work.admin_start_date = ['01/15/2017']
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#startDate/)
  end

  it 'has qr_status' do
    work.qr_status = ['qr status']
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#qr_status/)
  end

  it 'has rejection_reason' do
    work.rejection_reason = ['A rejection']
    expect(work.resource.dump(:ttl))
      .to match(/dl\.tufts\.edu\/terms#rejection_reason/)
  end

  it 'has quality review note' do
    work.qr_note = ['A note about the quality review']
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#qr_note/)
  end

  it 'has creator_department' do
    work.creator_department = ['A creator department']
    expect(work.resource.dump(:ttl))
      .to match(/dl\.tufts\.edu\/terms#creator_department/)
  end

  it 'has createdby' do
    work.createdby = ['self-deposit']
    expect(work.resource.dump(:ttl)).to match(/dl\.tufts\.edu\/terms#createdby/)
  end

  it 'has is_part_of' do
    work.is_part_of = ['Something bigger']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/isPartOf/)
  end

  it 'has a tufts_license' do
    work.tufts_license = ['An example tufts license']
    expect(work.resource.dump(:ttl))
      .to match(/purl\.org\/dc\/terms\/license/)
  end

  it 'has dc_access_rights' do
    work.dc_access_rights = ['True']
    expect(work.resource.dump(:ttl))
      .to match(/accessRights/)
  end
end

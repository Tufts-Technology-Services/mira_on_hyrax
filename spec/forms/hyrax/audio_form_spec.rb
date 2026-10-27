# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Audio`
require 'rails_helper'

RSpec.describe Hyrax::AudioForm do
  let(:audio) { Audio.new }
  let(:form) { described_class.new(audio, '', '') }

  it_behaves_like 'a form with Tufts metadata attributes'
  it_behaves_like 'a form with a transcription'

  describe '#transcript?' do
    it 'accepts TEI XML files' do
      expect(form.transcript?(double(mime_type: 'text/xml'), 'Audio')).to eq(true)
    end

    it 'accepts SRT files characterized as text/plain' do
      expect(form.transcript?(double(mime_type: 'text/plain'), 'Audio')).to eq(true)
    end

    it 'accepts SRT files characterized as application/x-subrip' do
      expect(form.transcript?(double(mime_type: 'application/x-subrip'), 'Audio')).to eq(true)
    end

    it 'rejects VTT files' do
      expect(form.transcript?(double(mime_type: 'text/vtt'), 'Audio')).to eq(false)
    end

    it 'rejects non-transcript files' do
      expect(form.transcript?(double(mime_type: 'audio/mpeg'), 'Audio')).to eq(false)
    end
  end
end

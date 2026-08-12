# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Tufts::CharacterizationService do
  let(:file) { Hydra::PCDM::File.new }

  before do
    described_class.run(file, 'test1234')
  end

  it 'assigns expected values to characterized properties.' do
    expect(file.samples_per_pixel).to eq [1]
    expect(file.x_resolution).to eq [600]
    expect(file.y_resolution).to eq [600]
    expect(file.resolution_unit).to eq ['inches']
    expect(file.bits_per_sample).to eq [8]
  end

  context 'when FITS identifies a WAV file as Microsoft Excel' do
    before do
      file.mime_type = 'application/vnd.ms-excel'
      allow_any_instance_of(described_class).to receive(:local_mime_type).and_return('audio/x-wav')
      described_class.run(file, '/tmp/UA136.004.024.00102.wav')
    end

    it 'corrects the mime type to WAV audio' do
      expect(file.mime_type).to eq 'audio/x-wav'
    end

    it 'replaces the format label' do
      expect(file.format_label).to eq ['Waveform Audio']
    end
  end

  context 'when a Microsoft Excel mime type is not a WAV file' do
    before do
      file.mime_type = 'application/vnd.ms-excel'
      allow_any_instance_of(described_class).to receive(:local_mime_type).and_return('audio/x-wav')
      described_class.run(file, '/tmp/workbook.xls')
    end

    it 'leaves the mime type alone' do
      expect(file.mime_type).to eq 'application/vnd.ms-excel'
    end
  end
end

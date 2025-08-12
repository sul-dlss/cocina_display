# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bb099mt5053" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.new(cocina_doc) }

  describe "#files" do
    it "returns an array of file hashes" do
      expect(subject.files).to be_an(Array)
      expect(subject.files.first).to be_a(Hash)
      expect(subject.files.first["filename"]).to eq("bb099mt5053_sl.m4a")
      expect(subject.files.first["size"]).to eq(13832365)
    end
  end

  describe "#file_mime_types" do
    it "returns an array of unique MIME types" do
      expect(subject.file_mime_types).to contain_exactly("audio/mp4", "image/jp2")
    end
  end

  describe "#total_file_size_str" do
    it "returns a human-readable string representation of the total file size" do
      expect(subject.total_file_size_str).to eq("14.1 MB")
    end
  end

  describe "#total_file_size_int" do
    it "returns the total file size in bytes" do
      expect(subject.total_file_size_int).to eq(14744206)
    end
  end
end

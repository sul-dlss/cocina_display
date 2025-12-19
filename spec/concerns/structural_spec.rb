# frozen_string_literal: true

require "spec_helper"

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

  describe "#containing_collections" do
    it "returns an array of collection DRUIDs" do
      expect(subject.containing_collections).to contain_exactly("sj775xm6965")
    end

    context "when the object is not a member of any collections" do
      before do
        cocina_doc["structural"].delete("isMemberOf")
      end

      it "returns an empty array" do
        expect(subject.containing_collections).to be_empty
      end
    end
  end

  describe "#virtual_object?" do
    context "when the object is a virtual object" do
      let(:druid) { "ws947mh3822" }

      it "returns true" do
        expect(subject.virtual_object?).to be true
      end
    end

    context "when the object is not a virtual object" do
      it "returns false" do
        expect(subject.virtual_object?).to be false
      end
    end
  end

  describe "#virtual_object_members" do
    context "when the object is a virtual object" do
      let(:druid) { "ws947mh3822" }

      it "returns an array of member DRUIDs" do
        expect(subject.virtual_object_members).to contain_exactly("ts786ny5936", "tp006ms8736", "tj297ys4758")
      end
    end

    context "when the object is not a virtual object" do
      it "returns an empty array" do
        expect(subject.virtual_object_members).to be_empty
      end
    end
  end
end

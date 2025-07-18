# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bx658jh7339" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.from_json(cocina_json) }

  describe "#content_type" do
    let(:druid) { "bx658jh7339" }

    it "returns the content type from the cocina document" do
      expect(subject.content_type).to eq "image"
    end
  end

  describe "#collection?" do
    context "with an item" do
      let(:druid) { "bx658jh7339" }

      it "returns false" do
        expect(subject.collection?).to be false
      end
    end

    context "with a collection" do
      let(:cocina_json) { File.read(file_fixture("nz187ct8959.json")) }

      it "returns true" do
        expect(subject.collection?).to be true
      end
    end
  end

  describe "#created_time" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct created time" do
      expect(subject.created_time).to eq Time.parse("2022-04-27T00:21:13.000+00:00")
    end
  end

  describe "#modified_time" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct modified time" do
      expect(subject.modified_time).to eq Time.parse("2022-04-27T00:21:13.000+00:00")
    end
  end

  describe "#label" do
    let(:druid) { "bx658jh7339" }

    it "returns the label" do
      expect(subject.label).to eq "M. de Courville : [estampe]"
    end
  end

  describe "#files" do
    let(:druid) { "bx658jh7339" }

    it "returns the files" do
      expect(subject.files.to_a.first).to include(
        "filename" => "T0000001.jp2",
        "size" => 824964,
        "version" => 1
      )
    end
  end
end

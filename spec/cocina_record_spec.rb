# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bx658jh7339" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.new(cocina_json) }

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

  describe "#title" do
    context "when there is a subtitle" do
      let(:druid) { "bx658jh7339" }

      it "returns the title formatted to include the subtitle" do
        expect(subject.title).to eq "M. de Courville : [estampe]"
      end
    end

    context "when there are escaped characters" do
      let(:druid) { "bb112zx3193" }

      it "renders the title correctly" do
        expect(subject.title).to eq "Bugatti Type 51A. Road & Track Salon January 1957"
      end
    end
  end

  describe "#additional_titles" do
    context "when there is an alternative title" do
      let(:druid) { "nz187ct8959" }

      it "returns the alternative title" do
        expect(subject.additional_titles).to eq ["Two thousand and ten China province population census data with GIS maps"]
      end
    end

    context "when there is a parallel translated title" do
      let(:druid) { "bt553vr2845" }

      it "returns the parallel title" do
        expect(subject.additional_titles).to eq ["Master i Margarita. English"]
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

  describe "#purl_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct PURL URL" do
      expect(subject.purl_url).to eq "https://purl.stanford.edu/bx658jh7339"
    end

    context "for a staging object" do
      let(:druid) { "qr918wy2257" }

      it "returns the correct PURL URL" do
        expect(subject.purl_url).to eq "https://sul-purl-stage.stanford.edu/qr918wy2257"
      end
    end
  end

  describe "#oembed_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct oEmbed URL" do
      expect(subject.oembed_url).to eq "https://purl.stanford.edu/embed.json?url=https%3A%2F%2Fpurl.stanford.edu%2Fbx658jh7339"
    end

    context "for a staging object" do
      let(:druid) { "qr918wy2257" }

      it "returns the correct oEmbed URL" do
        expect(subject.oembed_url).to eq "https://sul-purl-stage.stanford.edu/embed.json?url=https%3A%2F%2Fsul-purl-stage.stanford.edu%2Fqr918wy2257"
      end
    end
  end

  describe "#download_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct download URL" do
      expect(subject.download_url).to eq "https://stacks.stanford.edu/object/bx658jh7339"
    end

    context "for a staging object" do
      let(:druid) { "qr918wy2257" }

      it "returns the correct download URL" do
        expect(subject.download_url).to eq "https://sul-stacks-stage.stanford.edu/object/qr918wy2257"
      end
    end
  end

  describe "#iiif_manifest_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct IIIF manifest URL" do
      expect(subject.iiif_manifest_url).to eq "https://purl.stanford.edu/bx658jh7339/iiif3/manifest"
    end

    context "for IIIF version 2" do
      it "returns the correct IIIF manifest URL" do
        expect(subject.iiif_manifest_url(version: 2)).to eq "https://purl.stanford.edu/bx658jh7339/iiif/manifest"
      end
    end

    context "for a staging object" do
      let(:druid) { "qr918wy2257" }

      it "returns the correct IIIF manifest URL" do
        expect(subject.iiif_manifest_url).to eq "https://sul-purl-stage.stanford.edu/qr918wy2257/iiif3/manifest"
      end
    end
  end
end

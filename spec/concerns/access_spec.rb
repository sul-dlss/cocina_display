require "spec_helper"
require_relative "../../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bx658jh7339" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.from_json(cocina_json) }

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

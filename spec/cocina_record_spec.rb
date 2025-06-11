# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bx658jh7339" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.new(cocina_json) }

  describe "#druid" do
    let(:druid) { "bx658jh7339" }

    it "returns the druid from the cocina document" do
      expect(subject.druid).to eq "druid:bx658jh7339"
    end
  end

  describe "#bare_druid" do
    let(:druid) { "bx658jh7339" }

    it "returns the bare druid from the cocina document" do
      expect(subject.bare_druid).to eq "bx658jh7339"
    end
  end

  describe "#content_type" do
    let(:druid) { "bx658jh7339" }

    it "returns the content type from the cocina document" do
      expect(subject.content_type).to eq "image"
    end
  end

  describe "collection?" do
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

  describe "#purl_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct PURL URL" do
      expect(subject.purl_url).to eq "https://purl.stanford.edu/bx658jh7339"
    end

    context "for a staging object" do
      let(:druid) { "bh114dk3076" }
      let(:purl_base_url) { "https://sul-purl-stage.stanford.edu" }

      it "returns the correct PURL URL" do
        expect(subject.purl_url(purl_base_url: purl_base_url)).to eq "https://sul-purl-stage.stanford.edu/bh114dk3076"
      end
    end
  end

  describe "#oembed_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct oEmbed URL" do
      expect(subject.oembed_url).to eq "https://purl.stanford.edu/embed.json?url=https%3A%2F%2Fpurl.stanford.edu%2Fbx658jh7339"
    end

    context "for a staging object" do
      let(:druid) { "bh114dk3076" }
      let(:purl_base_url) { "https://sul-purl-stage.stanford.edu" }

      it "returns the correct oEmbed URL" do
        expect(subject.oembed_url(purl_base_url: purl_base_url)).to eq "https://sul-purl-stage.stanford.edu/embed.json?url=https%3A%2F%2Fsul-purl-stage.stanford.edu%2Fbh114dk3076"
      end
    end
  end

  describe "#download_url" do
    let(:druid) { "bx658jh7339" }

    it "returns the correct download URL" do
      expect(subject.download_url).to eq "https://stacks.stanford.edu/object/bx658jh7339"
    end

    context "for a staging object" do
      let(:druid) { "bh114dk3076" }
      let(:stacks_base_url) { "https://sul-stacks-stage.stanford.edu" }

      it "returns the correct download URL" do
        expect(subject.download_url(stacks_base_url: stacks_base_url)).to eq "https://sul-stacks-stage.stanford.edu/object/bh114dk3076"
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
      let(:druid) { "bh114dk3076" }
      let(:purl_base_url) { "https://sul-purl-stage.stanford.edu" }

      it "returns the correct IIIF manifest URL" do
        expect(subject.iiif_manifest_url(purl_base_url: purl_base_url)).to eq "https://sul-purl-stage.stanford.edu/bh114dk3076/iiif3/manifest"
      end
    end
  end
end

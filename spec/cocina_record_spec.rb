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

  describe "#doi" do
    context "when there is no DOI" do
      let(:druid) { "bx658jh7339" }

      it "returns nil" do
        expect(subject.doi).to be_nil
      end
    end

    context "when the DOI is listed under identifiers" do
      let(:druid) { "vk217bh4910" }

      it "returns the DOI without url" do
        expect(subject.doi).to eq "10.25740/ppax-bf07"
      end
    end

    context "when the DOI is listed under identification" do
      let(:druid) { "zs631wn7371" }

      it "returns the DOI without url" do
        expect(subject.doi).to eq "10.25740/zs631wn7371"
      end
    end

    context "when the DOI is only available as a URI" do
      let(:cocina_json) do
        {
          "description" => {
            "identifier" => [{
              "uri" => "https://doi.org/10.25740/ppax-bf07"
            }]
          }
        }.to_json
      end

      it "returns the DOI without url" do
        expect(subject.doi).to eq "10.25740/ppax-bf07"
      end
    end
  end

  describe "#doi_url" do
    context "when there is no DOI" do
      let(:druid) { "bx658jh7339" }

      it "returns nil" do
        expect(subject.doi_url).to be_nil
      end
    end

    context "when the DOI is listed under identifiers" do
      let(:druid) { "vk217bh4910" }

      it "returns the DOI URL" do
        expect(subject.doi_url).to eq "https://doi.org/10.25740/ppax-bf07"
      end
    end

    context "when the DOI is listed under identification" do
      let(:druid) { "zs631wn7371" }

      it "returns the DOI URL" do
        expect(subject.doi_url).to eq "https://doi.org/10.25740/zs631wn7371"
      end
    end

    context "when the DOI is only available as a URI" do
      let(:cocina_json) do
        {
          "description" => {
            "identifier" => [{
              "uri" => "https://doi.org/10.25740/ppax-bf07"
            }]
          }
        }.to_json
      end

      it "returns the DOI without url" do
        expect(subject.doi_url).to eq "https://doi.org/10.25740/ppax-bf07"
      end
    end
  end

  describe "#folio_hrid" do
    context "when there are no catalog links" do
      let(:druid) { "bx658jh7339" }

      it "returns nil" do
        expect(subject.folio_hrid).to be_nil
      end
    end

    context "when there is a Symphony catalog link" do
      let(:druid) { "bx658jh7339" }
      let(:cocina_json) do
        {
          "identification" => {
            "catalogLinks" => [
              {
                "catalog" => "symphony",
                "refresh" => true,
                "catalogRecordId" => "123456"
              }
            ]
          }
        }.to_json
      end

      it "returns nil" do
        expect(subject.folio_hrid).to be_nil
      end
    end

    context "when there is a FOLIO catalog link" do
      let(:druid) { "pv074by7080" }

      it "returns the correct id" do
        expect(subject.folio_hrid).to eq "a12845814"
      end
    end
  end

  describe "#searchworks_id" do
    context "when there is a catkey" do
      let(:druid) { "pv074by7080" }

      it "returns the catkey" do
        expect(subject.searchworks_id).to eq "a12845814"
      end
    end

    context "when there is no catkey" do
      let(:druid) { "bx658jh7339" }

      it "returns the druid" do
        expect(subject.searchworks_id).to eq "bx658jh7339"
      end
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

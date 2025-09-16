# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bx658jh7339" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.new(cocina_doc) }

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

  describe "#use_and_reproduction" do
    let(:druid) { "bb099mt5053" }

    it "returns the use and reproduction statement" do
      expect(subject.use_and_reproduction).to match "permission to examine collection materials is not an authorization to publish"
    end
  end

  describe "#copyright" do
    let(:druid) { "bb099mt5053" }

    it "returns the copyright statement" do
      expect(subject.copyright).to eq "Materials may be subject to copyright."
    end
  end

  describe "#license" do
    let(:druid) { "zw438wf4318" }

    it "returns the license URL" do
      expect(subject.license).to eq "https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode"
    end
  end

  describe "#license_description" do
    let(:druid) { "zw438wf4318" }

    it "returns the license description" do
      expect(subject.license_description).to match "Creative Commons Attribution Non Commercial No Derivatives 4.0 International license"
    end

    context "when there is no license" do
      let(:druid) { "bb099mt5053" }

      it "returns nil" do
        expect(subject.license_description).to be_nil
      end
    end

    context "when the license is not in the config" do
      let(:cocina_doc) do
        {
          "access" => {
            "license" => "http://example.com/license/not-in-config"
          }
        }
      end

      it "raises an error" do
        expect { subject.license_description }.to raise_error(CocinaDisplay::License::LegacyLicenseError)
      end
    end
  end
end

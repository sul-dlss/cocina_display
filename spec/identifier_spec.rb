# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Identifier do
  subject { described_class.new(cocina) }

  context "with a local identifier (no URI)" do
    let(:cocina) do
      {
        "type" => "local",
        "value" => "local-id-123"
      }
    end

    it "has an identifier value" do
      expect(subject.identifier).to eq("local-id-123")
    end

    it "uses the value for display" do
      expect(subject.to_s).to eq("local-id-123")
    end

    it "has a type of local" do
      expect(subject.type).to eq("local")
    end

    it "has no uri" do
      expect(subject.uri).to be_nil
    end

    it "has a generic label" do
      expect(subject.label).to eq("Identifier")
    end

    it { is_expected.not_to be_doi }
  end

  context "with a local identifier (with displayLabel)" do
    let(:cocina) do
      {
        "type" => "local",
        "value" => "local-id-123",
        "displayLabel" => "Local Identifier"
      }
    end

    it "uses the displayLabel" do
      expect(subject.label).to eq("Local Identifier")
    end

    it { is_expected.not_to be_doi }
  end

  context "with an ORCID (with URI)" do
    let(:cocina) do
      {
        "type" => "ORCID",
        "value" => "https://orcid.org/0000-0001-5028-5161"
      }
    end

    it "has a uri" do
      expect(subject.uri).to eq("https://orcid.org/0000-0001-5028-5161")
    end

    it "uses the uri for display" do
      expect(subject.to_s).to eq("https://orcid.org/0000-0001-5028-5161")
    end

    it "parses the identifier from the uri" do
      expect(subject.identifier).to eq("0000-0001-5028-5161")
    end

    it "has a type of ORCID" do
      expect(subject.type).to eq("ORCID")
    end

    it "has a specific label" do
      expect(subject.label).to eq("ORCID")
    end

    it { is_expected.not_to be_doi }
  end

  context "with an ORCID (without URI)" do
    let(:cocina) do
      {
        "value" => "0000-0003-1916-3929",
        "type" => "ORCID",
        "source" => {
          "uri" => "https://orcid.org"
        }
      }
    end

    it "has a uri" do
      expect(subject.uri).to eq("https://orcid.org/0000-0003-1916-3929")
    end
  end

  context "with a DOI (no URI)" do
    let(:cocina) do
      {
        "type" => "DOI",
        "value" => "10.1234/doi"
      }
    end

    it "generates a doi.org uri" do
      expect(subject.uri).to eq("https://doi.org/10.1234/doi")
    end

    it "uses the generated uri for display" do
      expect(subject.to_s).to eq("https://doi.org/10.1234/doi")
    end

    it "has an identifier value" do
      expect(subject.identifier).to eq("10.1234/doi")
    end

    it "has a type of DOI" do
      expect(subject.type).to eq("DOI")
    end

    it "has a specific label" do
      expect(subject.label).to eq("DOI")
    end

    it { is_expected.to be_doi }
  end

  context "with a DOI (with URI)" do
    let(:cocina) do
      {
        "type" => "DOI",
        "uri" => "https://doi.org/10.1234/doi"
      }
    end

    it "has a specific label" do
      expect(subject.label).to eq("DOI")
    end

    it "parses the identifier from the uri" do
      expect(subject.identifier).to eq("10.1234/doi")
    end

    it "uses the uri for display" do
      expect(subject.to_s).to eq("https://doi.org/10.1234/doi")
    end

    it { is_expected.to be_doi }
  end

  context "with a DOI (no type)" do
    let(:cocina) do
      {
        "uri" => "https://doi.org/10.1234/doi"
      }
    end

    it "parses the identifier from the uri" do
      expect(subject.identifier).to eq("10.1234/doi")
    end

    it "has a specific label" do
      expect(subject.label).to eq("DOI")
    end

    it "uses the uri for display" do
      expect(subject.to_s).to eq("https://doi.org/10.1234/doi")
    end

    it { is_expected.to be_doi }
  end

  context "with a DOI (with displayLabel)" do
    let(:cocina) do
      {
        "uri" => "https://doi.org/10.1234/doi",
        "displayLabel" => "Digital Object Identifier"
      }
    end

    it "uses the displayLabel" do
      expect(subject.label).to eq("Digital Object Identifier")
    end

    it { is_expected.to be_doi }
  end

  context "with an ISSN-L" do
    let(:cocina) do
      {
        "type" => "ISSN-L",
        "value" => "1234-5678"
      }
    end

    it "uses the ISSN label" do
      expect(subject.label).to eq("ISSN")
    end
  end
end

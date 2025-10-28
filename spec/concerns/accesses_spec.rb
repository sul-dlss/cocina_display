require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:descriptive_access) do
    {
      "digitalLocation" => [{"value" => "Series: The Prosecutor v. Sabino Gouveia Leite", "type" => "discovery", :displayLabel => "Special location"}],
      "accessContact" => [{"value" => "email@example.com", "type" => "email"}],
      "url" => [{"value" => "https://example.com", "displayLabel" => "My favorite website"}]
    }
  end
  let(:cocina_access) { {} }
  let(:cocina_json) do
    {
      "access" => cocina_access,
      "description" => {
        "access" => descriptive_access,
        "purl" => "https://purl.stanford.edu/km388vz4371"
      }
    }.to_json
  end
  subject(:record) { described_class.from_json(cocina_json) }

  describe "#access_display_data" do
    it "returns an array of access display data" do
      expect(record.access_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Special location", values: ["Series: The Prosecutor v. Sabino Gouveia Leite"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Location", values: contain_exactly(
          "https://purl.stanford.edu/km388vz4371",
          "https://example.com"
        )))
      )
    end
  end

  describe "#contact_email_display_data" do
    it "returns an array of access contact display data" do
      expect(record.contact_email_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Contact information", values: ["email@example.com"]))
      )
    end
  end

  describe "#use_and_reproduction_display_data" do
    let(:cocina_access) do
      {
        "useAndReproductionStatement" => "Available for use in research, teaching, and private study."
      }
    end

    it "returns the use and reproduction display data" do
      expect(record.use_and_reproduction_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          values: ["Available for use in research, teaching, and private study."],
          label: "Use and reproduction statement"
        ))
      )
    end

    context "when the use and reproduction statement is empty" do
      let(:cocina_access) do
        {
          "useAndReproductionStatement" => ""
        }
      end

      it "returns an empty array" do
        expect(record.use_and_reproduction_display_data).to be_empty
      end
    end

    context "when there is no use and reproduction statement" do
      let(:cocina_access) { {} }

      it "returns an empty array" do
        expect(record.use_and_reproduction_display_data).to be_empty
      end
    end
  end

  describe "#copyright_display_data" do
    let(:cocina_access) do
      {
        "copyright" => "Copyright 2022 Stanford University."
      }
    end

    it "returns the copyright display data" do
      expect(record.copyright_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          values: ["Copyright 2022 Stanford University."],
          label: "Copyright"
        ))
      )
    end

    context "when the copyright statement is empty" do
      let(:cocina_access) do
        {
          "copyright" => ""
        }
      end

      it "returns an empty array" do
        expect(record.copyright_display_data).to be_empty
      end
    end

    context "when there is no copyright statement" do
      let(:cocina_access) { {} }

      it "returns an empty array" do
        expect(record.copyright_display_data).to be_empty
      end
    end
  end

  describe "#license_display_data" do
    let(:cocina_access) do
      {
        "license" => "https://www.apache.org/licenses/LICENSE-2.0"
      }
    end

    it "returns the license display data" do
      expect(record.license_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          values: ["This work is licensed under an Apache License 2.0."],
          label: "License"
        ))
      )
    end
  end

  describe "access rights" do
    context "dark" do
      let(:cocina_access) do
        {
          "view" => "dark",
          "download" => "none"
        }
      end

      it { is_expected.not_to be_viewable }
      it { is_expected.not_to be_downloadable }
      it { is_expected.not_to be_world_access }
      it { is_expected.not_to be_stanford_access }
      it { is_expected.not_to be_stanford_only_access }
      it { is_expected.not_to be_location_only_access }
      it { is_expected.not_to be_citation_only_access }
      it { is_expected.to be_dark_access }
    end

    context "world view and download" do
      let(:cocina_access) do
        {
          "view" => "world",
          "download" => "world"
        }
      end

      it { is_expected.to be_viewable }
      it { is_expected.to be_downloadable }
      it { is_expected.to be_world_viewable }
      it { is_expected.to be_world_downloadable }
      it { is_expected.to be_world_access }
      it { is_expected.to be_stanford_access }
      it { is_expected.to be_stanford_viewable }
      it { is_expected.to be_stanford_downloadable }
      it { is_expected.not_to be_stanford_only_access }
      it { is_expected.not_to be_dark_access }
      it { is_expected.not_to be_location_only_access }
      it { is_expected.not_to be_citation_only_access }
    end

    context "world view, stanford only download" do
      let(:cocina_access) do
        {
          "view" => "world",
          "download" => "stanford"
        }
      end

      it { is_expected.to be_viewable }
      it { is_expected.to be_downloadable }
      it { is_expected.to be_world_viewable }
      it { is_expected.not_to be_world_downloadable }
      it { is_expected.not_to be_world_access }
      it { is_expected.to be_stanford_viewable }
      it { is_expected.to be_stanford_downloadable }
      it { is_expected.to be_stanford_access }
      it { is_expected.not_to be_stanford_only_access }
      it { is_expected.not_to be_dark_access }
      it { is_expected.not_to be_location_only_access }
      it { is_expected.not_to be_citation_only_access }
    end

    context "stanford only view and download" do
      let(:cocina_access) do
        {
          "view" => "stanford",
          "download" => "stanford"
        }
      end

      it { is_expected.to be_viewable }
      it { is_expected.to be_downloadable }
      it { is_expected.not_to be_world_viewable }
      it { is_expected.not_to be_world_downloadable }
      it { is_expected.not_to be_world_access }
      it { is_expected.to be_stanford_viewable }
      it { is_expected.to be_stanford_downloadable }
      it { is_expected.to be_stanford_access }
      it { is_expected.to be_stanford_only_access }
      it { is_expected.not_to be_dark_access }
      it { is_expected.not_to be_location_only_access }
      it { is_expected.not_to be_citation_only_access }
    end

    context "view and download at ars only" do
      let(:cocina_access) do
        {
          "view" => "location-based",
          "download" => "location-based",
          "location" => "ars"
        }
      end

      it { is_expected.to be_viewable }
      it { is_expected.to be_downloadable }
      it { is_expected.not_to be_world_viewable }
      it { is_expected.not_to be_world_downloadable }
      it { is_expected.not_to be_world_access }
      it { is_expected.not_to be_stanford_viewable }
      it { is_expected.not_to be_stanford_downloadable }
      it { is_expected.not_to be_stanford_only_access }
      it { is_expected.not_to be_stanford_access }
      it { is_expected.not_to be_dark_access }
      it { is_expected.not_to be_citation_only_access }
      it { is_expected.to be_location_only_viewable }
      it { is_expected.to be_location_only_downloadable }
      it { is_expected.to be_location_only_access }
      it { is_expected.to be_viewable_at_location("ars") }
      it { is_expected.not_to be_viewable_at_location("spec") }
    end

    context "view at spec only, no download" do
      let(:cocina_access) do
        {
          "view" => "location-based",
          "download" => "none",
          "location" => "spec"
        }
      end

      it { is_expected.to be_viewable }
      it { is_expected.not_to be_downloadable }
      it { is_expected.not_to be_world_viewable }
      it { is_expected.not_to be_world_downloadable }
      it { is_expected.not_to be_world_access }
      it { is_expected.not_to be_stanford_viewable }
      it { is_expected.not_to be_stanford_downloadable }
      it { is_expected.not_to be_stanford_only_access }
      it { is_expected.not_to be_stanford_access }
      it { is_expected.not_to be_dark_access }
      it { is_expected.to be_location_only_viewable }
      it { is_expected.not_to be_location_only_downloadable }
      it { is_expected.not_to be_location_only_access }
      it { is_expected.not_to be_citation_only_access }
      it { is_expected.to be_viewable_at_location("spec") }
      it { is_expected.not_to be_viewable_at_location("ars") }
    end

    context "citation only" do
      let(:cocina_access) do
        {
          "view" => "citation-only",
          "download" => "none"
        }
      end

      it { is_expected.to be_viewable }
      it { is_expected.not_to be_downloadable }
      it { is_expected.not_to be_world_viewable }
      it { is_expected.not_to be_world_downloadable }
      it { is_expected.not_to be_world_access }
      it { is_expected.not_to be_stanford_viewable }
      it { is_expected.not_to be_stanford_downloadable }
      it { is_expected.not_to be_stanford_only_access }
      it { is_expected.not_to be_dark_access }
      it { is_expected.not_to be_stanford_access }
      it { is_expected.not_to be_location_only_viewable }
      it { is_expected.not_to be_location_only_downloadable }
      it { is_expected.not_to be_location_only_access }
      it { is_expected.to be_citation_only_access }
    end
  end

  describe "#accesses" do
    it "returns an array of Access objects" do
      expect(record.accesses).to contain_exactly(
        be_a(CocinaDisplay::Description::Access).and(have_attributes(type: "discovery", to_s: "Series: The Prosecutor v. Sabino Gouveia Leite"))
      )
    end
  end

  describe "#access_contacts" do
    it "returns an array of AccessContact objects" do
      expect(record.access_contacts).to contain_exactly(
        be_a(CocinaDisplay::Description::AccessContact).and(have_attributes(type: "email", to_s: "email@example.com"))
      )
    end
  end

  describe "#urls" do
    it "returns an array of Url objects" do
      expect(record.urls).to contain_exactly(
        be_a(CocinaDisplay::Description::Url).and(have_attributes(link_text: "My favorite website", to_s: "https://example.com"))
      )
    end
  end
end

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
  let(:record) { described_class.from_json(cocina_json) }

  describe "#access_display_data" do
    it "returns an array of access display data" do
      expect(record.access_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Special location", values: ["Series: The Prosecutor v. Sabino Gouveia Leite"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Location", values: contain_exactly(
          be_a(CocinaDisplay::DisplayData::LinkData).and(have_attributes(link_text: nil, url: "https://purl.stanford.edu/km388vz4371")),
          be_a(CocinaDisplay::DisplayData::LinkData).and(have_attributes(link_text: "My favorite website", url: "https://example.com"))
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

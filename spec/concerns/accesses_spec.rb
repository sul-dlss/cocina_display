require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:accesses) do
    {
      "digitalLocation" => [{"value" => "Series: The Prosecutor v. Sabino Gouveia Leite", "type" => "discovery", :displayLabel => "Special location"}],
      "accessContact" => [{"value" => "email@example.com", "type" => "email"}],
      "url" => [{"value" => "https://example.com", "displayLabel" => "My favorite website"}]
    }
  end
  let(:cocina_json) do
    {
      "description" => {
        "access" => accesses,
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

  describe "#accesses" do
    it "returns an array of Access objects" do
      expect(record.accesses).to contain_exactly(
        be_a(CocinaDisplay::Access).and(have_attributes(type: "discovery", to_s: "Series: The Prosecutor v. Sabino Gouveia Leite"))
      )
    end
  end

  describe "#access_contacts" do
    it "returns an array of AccessContact objects" do
      expect(record.access_contacts).to contain_exactly(
        be_a(CocinaDisplay::Accesses::AccessContact).and(have_attributes(type: "email", to_s: "email@example.com"))
      )
    end
  end

  describe "#urls" do
    it "returns an array of Url objects" do
      expect(record.urls).to contain_exactly(
        be_a(CocinaDisplay::Accesses::Url).and(have_attributes(link_text: "My favorite website", to_s: "https://example.com"))
      )
    end
  end
end

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bx658jh7339" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.from_json(cocina_json) }

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

    context "when there is a non-refreshed FOLIO catalog link" do
      let(:druid) { "pv074by7080" }
      let(:cocina_json) do
        {
          "identification" => {
            "catalogLinks" => [
              {
                "catalog" => "folio",
                "refresh" => false,
                "catalogRecordId" => "a12845814"
              }
            ]
          }
        }.to_json
      end

      context "no refresh option" do
        it "returns the catalog record id" do
          expect(subject.folio_hrid).to eq "a12845814"
        end
      end

      context "when refresh is true" do
        it "returns nil" do
          expect(subject.folio_hrid(refresh: true)).to be_nil
        end
      end

      context "when refresh is false" do
        it "returns the catalog record id" do
          expect(subject.folio_hrid(refresh: false)).to eq "a12845814"
        end
      end
    end
  end

  describe "#searchworks_id" do
    context "when there is a folio hrid" do
      let(:druid) { "pv074by7080" }

      it "returns the folio hrid" do
        expect(subject.searchworks_id).to eq "a12845814"
      end
    end

    context "when there is no folio hrid" do
      let(:druid) { "bx658jh7339" }

      it "returns the druid" do
        expect(subject.searchworks_id).to eq "bx658jh7339"
      end
    end
  end

  describe "#identifier_display_data" do
    subject { described_class.new(cocina_doc) }

    let(:cocina_doc) do
      {
        "description" => {
          "identifier" => [
            {
              "type" => "doi",
              "value" => "10.25740/ppax-bf07"
            },
            {
              "type" => "doi",
              "value" => "https://doi.org/10.25740/sb4q-wj06"
            },
            {
              "type" => "isbn",
              "value" => "978-0-061-96436-7"
            },
            {
              "type" => "other",
              "value" => "other-id-123"
            },
            {
              "type" => "other",
              "value" => "other-id-123"
            },
            {
              "type" => "other",
              "value" => ""
            },
            {
              "type" => "lccn",
              "value" => ""
            },
            {
              "type" => "other",
              "value" => "other-id-456"
            },
            {
              "type" => "custom",
              "value" => "custom-id-123",
              "displayLabel" => "Custom label"
            }
          ]
        }
      }
    end

    it "returns an array of DisplayValue objects" do
      expect(subject.identifier_display_data).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "DOI", values: contain_exactly(
          be_a(CocinaDisplay::DisplayData::LinkData).and(have_attributes(link_text: nil, url: "https://doi.org/10.25740/ppax-bf07")),
          be_a(CocinaDisplay::DisplayData::LinkData).and(have_attributes(link_text: nil, url: "https://doi.org/10.25740/sb4q-wj06"))
        ))),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "ISBN", values: ["978-0-061-96436-7"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Identifier", values: ["other-id-123", "other-id-456"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Custom label", values: ["custom-id-123"]))
      )
    end
  end
end

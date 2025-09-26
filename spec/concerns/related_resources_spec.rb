# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:related_resources) { [] }
  let(:cocina) do
    {
      "description" => {
        "relatedResource" => related_resources
      }
    }
  end
  let(:record) { described_class.new(cocina) }

  describe "#related_resources" do
    let(:druid) { "vk217bh4910" }
    let(:cocina) { JSON.parse(File.read(file_fixture("#{druid}.json"))) }

    subject { record.related_resources }

    it "returns all related resources" do
      expect(subject.size).to eq(10)
    end

    it "knows the type of the relationship" do
      expect(subject.first.type).to eq "succeeded by"
    end

    it "supports calling CocinaRecord methods on the related resources" do
      expect(subject.first.doi).to eq "10.25740/sb4q-wj06"
    end
  end

  describe "#related_resource_display_data" do
    subject { CocinaDisplay::DisplayData.to_hash(record.related_resource_display_data) }

    # taken from druid:hp566jq8781
    context "with relations that include display labels" do
      let(:related_resources) do
        [
          {
            "type" => "referenced by",
            "displayLabel" => "Downloadable James Catalogue Record",
            "title" => [{"value" => "https://stacks.stanford.edu/file/druid:vz744tc9861/MS_367.pdf"}]
          },
          {
            "type" => "referenced by",
            "displayLabel" => "Superseded Interim Catalogue Record",
            "title" => [{"value" => "https://stacks.stanford.edu/file/druid:pw577ky6421/367.pdf"}]
          }
        ]
      end

      it "uses the display labels" do
        is_expected.to eq(
          {
            "Downloadable James Catalogue Record" => ["https://stacks.stanford.edu/file/druid:vz744tc9861/MS_367.pdf"],
            "Superseded Interim Catalogue Record" => ["https://stacks.stanford.edu/file/druid:pw577ky6421/367.pdf"]
          }
        )
      end
    end

    # druid:bc151bq1744
    context "with title type items that have part information and a URL" do
      let(:related_resources) do
        [
          {
            "type" => "referenced by",
            "title" => [{"value" => "Wardington, Lord: The Book Collector, 2003 "}],
            "note" => [
              {
                "groupedValue" => [
                  {"value" => "vol. 52 pgs 199-211 & 317-355", "type" => "number"},
                  {"value" => "part", "type" => "detail type"}
                ],
                "type" => "part"
              }
            ]
          },
          {
            "type" => "referenced by",
            "title" => [{"value" => "Phillips "}],
            "note" => [
              {
                "groupedValue" => [
                  {"value" => "203", "type" => "number"},
                  {"value" => "part", "type" => "detail type"}
                ],
                "type" => "part"
              }
            ]
          },
          {
            "type" => "referenced by",
            "title" => [{"value" => "Tooley "}],
            "note" => [
              {
                "groupedValue" => [
                  {"value" => "395", "type" => "number"},
                  {"value" => "part", "type" => "detail type"}
                ],
                "type" => "part"
              }
            ]
          },
          {
            "purl" => "https://purl.stanford.edu/wj967bm6421"
          }
        ]
      end

      it "returns display data with titles and part information" do
        is_expected.to eq(
          {
            "Referenced by" => [
              "Wardington, Lord: The Book Collector, 2003. vol. 52 pgs 199-211 & 317-355",
              "Phillips. 203",
              "Tooley. 395"
            ],
            "Related item" => ["https://purl.stanford.edu/wj967bm6421"]
          }
        )
      end
    end

    context "with related resources with DOIs" do
      let(:related_resources) do
        [
          {
            "type" => "succeeded by",
            "identifier" => [
              {
                "value" => "10.25740/sb4q-wj06",
                "type" => "doi"
              }
            ]
          },
          {
            "type" => "supplement to",
            "identifier" => [
              {
                "value" => "10.1234/abcde",
                "type" => "doi"
              }
            ]
          }
        ]
      end

      it "returns display data with the DOIs" do
        is_expected.to eq(
          {
            "Succeeded by" => ["https://doi.org/10.25740/sb4q-wj06"],
            "Supplement to" => ["https://doi.org/10.1234/abcde"]
          }
        )
      end
    end
  end
end

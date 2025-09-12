require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:forms) { [] }
  let(:events) { [] }
  let(:subjects) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "form" => forms,
        "event" => events,
        "subject" => subjects
      }
    }.to_json
  end
  let(:record) { described_class.from_json(cocina_json) }

  describe "#resource_types" do
    subject { record.resource_types }

    context "with general mapped resource types" do
      let(:forms) do
        [
          {"value" => "mixed material", "type" => "resource type"},
          {"value" => "manuscript", "type" => "resource type"},
          {"value" => "cartographic", "type" => "resource type"},
          {"value" => "moving image", "type" => "resource type"},
          {"value" => "notated music", "type" => "resource type"},
          {"value" => "software, multimedia", "type" => "resource type"},
          {"value" => "sound recording-musical", "type" => "resource type"},
          {"value" => "sound recording-nonmusical", "type" => "resource type"},
          {"value" => "still image", "type" => "resource type"},
          {"value" => "text", "type" => "resource type"},
          {"value" => "three dimensional object", "type" => "resource type"}
        ]
      end

      it "maps and deduplicates the values" do
        is_expected.to eq(["Archive/Manuscript", "Map", "Video", "Music score", "Music recording", "Sound recording", "Image", "Book", "Object"])
      end
    end

    context "with a periodical" do
      let(:events) do
        [
          {"note" => [{"value" => "periodical", "type" => "issuance"}]}
        ]
      end

      let(:forms) do
        [
          {"value" => "text", "type" => "resource type"}
        ]
      end

      it { is_expected.to eq(["Journal/Periodical"]) }
    end

    context "with a web archive" do
      let(:forms) do
        [
          {"value" => "text", "type" => "resource type"},
          {"value" => "archived website", "type" => "genre"}
        ]
      end

      it do
        is_expected.to eq(["Archived website"])
      end
    end
  end

  describe "#forms" do
    subject { record.forms }

    context "with simple form values" do
      let(:forms) do
        [
          {"value" => "electronic resource", "type" => "form"},
          {"value" => "optical disc", "type" => "form"},
          {"value" => "map", "type" => "form"}
        ]
      end

      it "extracts the values" do
        is_expected.to eq(["electronic resource", "optical disc", "map"])
      end
    end

    context "with grouped values (fixture data)" do
      let(:druid) { "sw705fr7011" }
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }

      it "extracts the individual form values" do
        is_expected.to eq(["audiotape reel"])
      end
    end
  end

  describe "#extents" do
    subject { record.extents }

    context "with simple extent values" do
      let(:forms) do
        [
          {"value" => "1 audiotape", "type" => "extent"},
          {"value" => "1 map", "type" => "extent"}
        ]
      end

      it "returns the extents" do
        is_expected.to eq(["1 audiotape", "1 map"])
      end
    end

    context "with grouped values (fixture data)" do
      let(:druid) { "sw705fr7011" }
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }

      it "extracts the individual extent values" do
        is_expected.to eq(["1 audiotape", "1 transcript"])
      end
    end
  end

  describe "#genres" do
    subject { record.genres }

    context "with genre values" do
      let(:forms) do
        [
          {"value" => "picture", "type" => "genre"},
          {"value" => "Picture", "type" => "genre"},
          {"value" => "Portraits-18e siècle.", "type" => "genre"}
        ]
      end

      it "capitalizes and deduplicates genres" do
        is_expected.to eq(["Picture", "Portraits-18e siècle."])
      end
    end
  end

  describe "#genres_search" do
    subject { record.genres_search }

    context "with genres that are mapped to SearchWorks values" do
      let(:forms) do
        [
          {"value" => "thesis", "type" => "genre"},
          {"value" => "conference publication", "type" => "genre"},
          {"value" => "government publication", "type" => "genre"}
        ]
      end

      it "maps genres to additional SearchWorks values" do
        is_expected.to eq(["Thesis", "Conference publication", "Government publication", "Thesis/Dissertation", "Conference proceedings", "Government document"])
      end
    end
  end

  describe "#map_display_data" do
    subject { record.map_display_data }

    let(:forms) do
      [
        {"value" => "[ca.1:60,000,000]", "type" => "map scale"},
        {"value" => "EPSG:4326", "type" => "map projection"}
      ]
    end
    let(:subjects) do
      [
        {"value" => "W 18°--E 51°/N 37°--S 35°", "type" => "map coordinates"},
        {"value" => "maps", "type" => "topic"}  # ignored
      ]
    end

    it "groups map-related data into separate labelled map data section" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          label: "Map data",
          values: [
            "[ca.1:60,000,000]",
            "EPSG:4326",
            "18°00′00″W -- 51°00′00″E / 37°00′00″N -- 35°00′00″S"
          ]
        ))
      )
    end
  end

  describe "#genre_display_data" do
    subject { record.genre_display_data }

    let(:forms) do
      [
        {"value" => "picture", "type" => "genre"},
        {"value" => "portrait", "type" => "genre"}
      ]
    end
    let(:subjects) do
      [
        {"value" => "Portrait", "type" => "genre"}, # duplicate
        {"value" => "biography", "type" => "genre"},
        {"value" => "painting", "type" => "topic"} # ignored
      ]
    end

    it "combines, capitalizes and deduplicates genre forms and subject forms" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          label: "Genre",
          values: ["Picture", "Portrait", "Biography"]
        ))
      )
    end
  end

  describe "#form_display_data" do
    subject { record.form_display_data }

    # Contrived example with some ignored values
    let(:forms) do
      [
        {"value" => "electronic resource", "type" => "form"},
        {"value" => "optical disc", "type" => "form", "displayLabel" => "Physical format"}, # custom label
        {"value" => "map", "type" => "form"},
        {"value" => "1 online resource.", "type" => "extent"},
        {"value" => "picture", "type" => "genre"},  # ignored
        {"value" => "[ca.1:60,000,000]", "type" => "map scale"}, # ignored
        {"value" => "EPSG:4326", "type" => "map projection"}, # ignored
        {"value" => "text", "type" => "media type"} # ignored
      ]
    end

    it "aggregates all form data that doesn't go into the other sections" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          label: "Physical format",
          values: ["optical disc"]
        )),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          label: "Form",
          values: ["electronic resource", "map"]
        )),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          label: "Extent",
          values: ["1 online resource."]
        ))
      )
    end

    context "with multiple kinds of resource type" do
      let(:forms) do
        [
          {
            "structuredValue" => [
              {"value" => "Text", "type" => "type"},
              {"value" => "Policy brief", "type" => "subtype"}
            ],
            "type" => "resource type",
            "source" => {
              "value" => "Stanford self-deposit resource types"
            }
          },
          {
            "value" => "text",
            "type" => "resource type",
            "source" => {"value" => "MODS resource types"}
          },
          {
            "value" => "Text",
            "type" => "resource type",
            "source" => {"value" => "DataCite resource types"}
          },
          {
            "value" => "Something else",
            "type" => "form"
          }
        ]
      end

      it "deduplicates and formats the resource types separately, excluding self-deposit" do
        is_expected.to contain_exactly(
          be_a(CocinaDisplay::DisplayData).and(have_attributes(
            label: "Type of resource",
            values: ["text"]
          )),
          be_a(CocinaDisplay::DisplayData).and(have_attributes(
            label: "Form",
            values: ["Something else"]
          ))
        )
      end
    end
  end
end

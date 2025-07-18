require "spec_helper"
require_relative "../../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:forms) { [] }
  let(:events) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "form" => forms,
        "event" => events
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

    let(:forms) do
      [
        {"value" => "electronic resource", "type" => "form"},
        {"value" => "optical disc", "type" => "form"},
        {"value" => "map", "type" => "form"}
      ]
    end

    it { is_expected.to eq(["electronic resource", "optical disc", "map"]) }
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
end

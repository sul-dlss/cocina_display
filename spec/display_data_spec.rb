# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::DisplayData do
  describe ".from_objects" do
    subject { described_class.from_objects(objects) }
    let(:objects) do
      [
        {"value" => "English"},
        {"value" => "Spanish"},
        {"value" => ""},
        {"code" => "eng", "source" => {"code" => "iso639-2"}},
        {"value" => "English"},
        {"code" => "zxx"},
        {"code" => "egy-Egyd"},
        {"value" => "Sumerian", "displayLabel" => "Primary language"}
      ].map { |lang| CocinaDisplay::Language.new(lang) }
    end

    it "groups objects by label and keeps unique, non-blank values" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Language", values: ["English", "Spanish", "Egyptian, Demotic"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Primary language", values: ["Sumerian"]))
      )
    end
  end

  describe ".from_cocina" do
    subject { described_class.from_cocina(cocina, label: "Language") }
    let(:cocina) do
      [
        {"value" => "English"},
        {"value" => "Spanish"},
        {"value" => ""},
        {"value" => "English"},
        {"value" => "Sumerian", "displayLabel" => "Primary language"}
      ]
    end

    it "groups objects by label and keeps unique, non-blank values" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Language", values: ["English", "Spanish"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Primary language", values: ["Sumerian"]))
      )
    end
  end

  describe ".from_string" do
    subject { described_class.from_string(value, label: label) }
    let(:value) { "Some text" }
    let(:label) { "Some label" }

    it "returns an array containing a DisplayData object" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Some label", values: ["Some text"]))
      )
    end
  end

  describe ".descriptive_values_from_string" do
    subject { described_class.descriptive_values_from_string(string, label: label) }
    let(:string) { "Some text" }
    let(:label) { "Some label" }

    it "returns an array containing an object with label and value attributes" do
      is_expected.to contain_exactly(
       have_attributes(label: "Some label", value: "Some text")
     )
    end
  end

  describe "#label" do
    subject { described_class.new(label: label, objects: objects).label }
    let(:label) { "Some label" }
    let(:objects) do
      [
        {"value" => "Some text"}
      ].map { |obj| CocinaDisplay::Language.new(obj) }
    end

    it "returns the label as supplied" do
      is_expected.to eq("Some label")
    end
  end

  describe "#values" do
    subject { described_class.new(label: label, objects: objects).values }
    let(:label) { "Some label" }
    let(:objects) do
      [
        {"value" => ""},
        {"value" => nil},
        {"value" => "A real note"},
        {"value" => "https://example.com"},
        {"value" => "A note with a URL in the middle of the text https://example.com and more text"}
      ].map { |obj| CocinaDisplay::Note.new(obj) }
    end

    it "returns the values from the objects" do
      is_expected.to contain_exactly("A real note",
        be_a(CocinaDisplay::DisplayData::LinkData).and(have_attributes(link_text: nil, url: "https://example.com")),
        "A note with a URL in the middle of the text https://example.com and more text")
    end

    context "when some of the supplied values contain newline characters" do
      let(:objects) do
        [
          {"value" => "Some text\nwith a note"},
          {"value" => "Another note"}
        ].map { |obj| CocinaDisplay::Note.new(obj) }
      end

      it "returns the values from the objects, splitting on newlines" do
        is_expected.to eq(["Some text", "with a note", "Another note"])
      end
    end
  end
end

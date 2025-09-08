# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Note do
  subject { described_class.new(note) }

  describe "#to_s" do
    let(:note) do
      {"value" => "A note about a thing."}
    end

    it "returns the value for note" do
      expect(subject.to_s).to eq "A note about a thing."
    end

    context "when the value is an empty string" do
      let(:note) do
        {"value" => ""}
      end

      it "returns nil" do
        expect(subject.to_s).to be_nil
      end
    end

    context "with a structuredValue" do
      let(:note) do
        {"structuredValue" => [{"value" => "A note about a thing."}, {"value" => "Another note about a thing."}]}
      end

      it "returns the concatenated values" do
        expect(subject.to_s).to eq "A note about a thing. -- Another note about a thing."
      end
    end
  end

  describe "#type" do
    let(:note) do
      {"value" => "A note about a thing.", "type" => "abstract"}
    end

    it "returns the type for note" do
      expect(subject.type).to eq "abstract"
    end

    context "when the type is not set" do
      let(:note) do
        {"value" => "A note about a thing."}
      end

      it "returns nil" do
        expect(subject.type).to be_nil
      end
    end
  end

  describe "#display_label" do
    let(:note) do
      {"value" => "A note about a thing.", "displayLabel" => "A special note"}
    end

    it "returns the displayLabel for note" do
      expect(subject.display_label).to eq "A special note"
    end

    context "when displayLabel is not set" do
      let(:note) do
        {"value" => "A note about a thing."}
      end

      it "returns nil" do
        expect(subject.display_label).to be_nil
      end
    end
  end

  describe "#label" do
    let(:note) do
      {"value" => "A note about a thing."}
    end

    it "returns the default label for note" do
      expect(subject.label).to eq "Note"
    end

    context "when displayLabel is set" do
      let(:note) do
        {
          "value" => "A special note about a thing.",
          "displayLabel" => "A special note"
        }
      end

      it "returns the displayLabel for note" do
        expect(subject.label).to eq "A special note"
      end
    end

    context "when a translated label is available for the type" do
      let(:note) do
        {
          "value" => "A note about a thing.",
          "type" => "biographical historical"
        }
      end

      it "returns the translated label for note" do
        expect(subject.label).to eq "Biographical/Historical"
      end
    end

    context "when a translated label is not available for the type" do
      let(:note) do
        {
          "value" => "A note about a thing.",
          "type" => "special note"
        }
      end

      it "returns the capitalized type as the label" do
        expect(subject.label).to eq "Special note"
      end
    end
  end

  describe "#abstract?" do
    let(:note) do
      {"value" => "A note about a thing.", "type" => "abstract"}
    end

    it "returns true for an abstract note" do
      expect(subject.abstract?).to be true
    end

    context "when the displayLabel indicates the type" do
      let(:note) do
        {"value" => "A note about a thing.", "displayLabel" => "Abstract"}
      end

      it "returns true" do
        expect(subject.abstract?).to be true
      end
    end

    context "when the note is not an abstract note" do
      let(:note) do
        {"value" => "A note about a thing.", "type" => "table of contents"}
      end

      it "returns false" do
        expect(subject.abstract?).to be false
      end
    end
  end

  describe "#general_note?" do
    let(:note) do
      {"value" => "A note about a thing.", "type" => "note"}
    end

    it "returns true for a generic note" do
      expect(subject.general_note?).to be true
    end

    context "when the note is not a generic note" do
      let(:note) do
        {"value" => "A note about a thing.", "type" => "abstract"}
      end

      it "returns false" do
        expect(subject.general_note?).to be false
      end
    end

    context "when the displayLabel indicates the type" do
      let(:note) do
        {"value" => "A note about a thing.", "displayLabel" => "Abstract"}
      end

      it "returns false" do
        expect(subject.general_note?).to be false
      end
    end
  end

  describe "#preferred_citation?" do
    let(:note) do
      {"value" => "A note about a thing.", "type" => "preferred citation"}
    end

    it "returns true for a preferred citation note" do
      expect(subject.preferred_citation?).to be true
    end

    context "when the displayLabel indicates the type" do
      let(:note) do
        {"value" => "A note about a thing.", "displayLabel" => "Preferred Citation"}
      end

      it "returns true" do
        expect(subject.preferred_citation?).to be true
      end
    end

    context "when the note is not a preferred citation note" do
      let(:note) do
        {"value" => "A note about a thing.", "type" => "abstract"}
      end

      it "returns false" do
        expect(subject.preferred_citation?).to be false
      end
    end
  end

  describe "#table_of_contents?" do
    let(:note) do
      {"value" => "A note about a thing.", "type" => "table of contents"}
    end

    it "returns true for a table of contents note" do
      expect(subject.table_of_contents?).to be true
    end

    context "when the displayLabel indicates the type" do
      let(:note) do
        {"value" => "A note about a thing.", "displayLabel" => "Table of Contents"}
      end

      it "returns true" do
        expect(subject.table_of_contents?).to be true
      end
    end

    context "when the note is not a table of contents note" do
      let(:note) do
        {"value" => "A note about a thing.", "type" => "abstract"}
      end

      it "returns false" do
        expect(subject.table_of_contents?).to be false
      end
    end
  end
end

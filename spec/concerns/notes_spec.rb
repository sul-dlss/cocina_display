# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:cocina_json) do
    {
      "description" => {
        "note" => notes
      }
    }.to_json
  end
  let(:record) { described_class.from_json(cocina_json) }
  let(:notes) do
    [
      {value: "This is a note"},
      {value: "This is an abstract", type: "abstract"},
      {value: "This is a citation", type: "preferred citation"},
      {structuredValue: [{value: "This is a table of contents"},
        {value: "With structured values"}],
       type: "table of contents"}
    ]
  end

  describe "#notes" do
    subject { record.notes }

    context "with no notes" do
      let(:notes) { [] }

      it "returns an empty array" do
        expect(record.notes).to eq []
      end
    end

    context "with notes" do
      let(:notes) do
        [
          {value: "This is a note"},
          {value: "This is another note", type: "biographical historical"}
        ]
      end

      it "returns an array of Note objects" do
        expect(record.notes).to contain_exactly(
          be_a(CocinaDisplay::Note).and(have_attributes(to_s: "This is a note", type: nil, label: "Note")),
          be_a(CocinaDisplay::Note).and(have_attributes(to_s: "This is another note", type: "biographical historical", label: "Biographical/Historical"))
        )
      end
    end
  end

  describe "#abstracts" do
    subject { record.abstracts }

    let(:notes) do
      [
        {value: "This is a note"},
        {value: "This is an abstract", type: "abstract"}
      ]
    end

    it "returns the abstract note texts" do
      expect(subject).to eq ["This is an abstract"]
    end
  end

  describe "#tables_of_contents" do
    subject { record.tables_of_contents }

    let(:notes) do
      [
        {value: "This is a note"},
        {structuredValue: [{value: "This is a table of contents"},
          {value: "With structured values"}],
         type: "table of contents"}
      ]
    end

    it "returns the table of contents note texts" do
      expect(subject).to eq ["This is a table of contents -- With structured values"]
    end
  end

  describe "#preferred_citation" do
    subject { record.preferred_citation }

    let(:notes) do
      [
        {value: "This is a note"},
        {value: "This is a citation", type: "preferred citation"}
      ]
    end

    it "returns the preferred citation note text" do
      expect(subject).to eq "This is a citation"
    end
  end

  describe "#abstract_display_data" do
    subject { record.abstract_display_data }

    it "returns an array of note display data" do
      expect(subject).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(values: ["This is an abstract"], label: "Abstract"))
      )
    end
  end

  describe "#general_note_display_data" do
    subject { record.general_note_display_data }

    it "returns an array of note display data" do
      expect(subject).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(values: ["This is a note"], label: "Note"))
      )
    end
  end

  describe "#preferred_citation_display_data" do
    subject { record.preferred_citation_display_data }

    it "returns an array of note display data" do
      expect(subject).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(values: ["This is a citation"], label: "Preferred citation"))
      )
    end
  end

  describe "#table_of_contents_display_data" do
    subject { record.table_of_contents_display_data }

    it "returns an array of note display data" do
      expect(subject).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(
          have_attributes(values: ["This is a table of contents -- With structured values"], label: "Table of contents")
        )
      )
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Notes::Note do
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
        expect(subject.to_s).to eq "A note about a thing. Another note about a thing."
      end
    end

    context "with a structuredValue when the note is a table of contents" do
      let(:note) do
        {"structuredValue" => [{"value" => "pt.1. A note about a thing."}, {"value" => "pt.2. Another note about a thing."}], "type" => "table of contents"}
      end

      it "returns the concatenated values with delimiter" do
        expect(subject.to_s).to eq "pt.1. A note about a thing. -- pt.2. Another note about a thing."
      end
    end

    context "with a value that has a delimiter inside it, but not at the end" do
      let(:note) do
        {"value" => "A note about a thing. -- With a delimiter."}
      end

      it "leaves the delimiter alone" do
        expect(subject.to_s).to eq "A note about a thing. -- With a delimiter."
      end
    end

    context "with a non-TOC note" do
      # from druid:gx074xz5520
      let(:note) do
        {
          "value" => "Stanford University. Cabinet, Stanford University--Administration.",
          "type" => "preferred citation"
        }
      end

      it "leaves the value unchanged" do
        expect(subject.to_s).to eq "Stanford University. Cabinet, Stanford University--Administration."
      end
    end

    context "with a TOC with delimiters in the values" do
      # from druid:bm971cx9348
      let(:note) do
        {
          "structuredValue" => [
            {"value" => "-- pt.2. Abergavenny"},
            {"value" => "-- pt.5. Merthyr Tydfil --"}
          ],
          "type" => "table of contents",
          "displayLabel" => "Incomplete contents"
        }
      end

      it "returns the values joined with delimiter" do
        expect(subject.to_s).to eq "pt.2. Abergavenny -- pt.5. Merthyr Tydfil"
      end
    end

    context "with a TOC with delimiters in a single value" do
      # from druid:sw284bk0647
      let(:note) do
        {
          "type" => "table of contents",
          # rubocop:disable Layout/LineLength
          "value" => "Progress: its law and cause.--Manners and fashion.--The genesis of science.--The physiology of laughter.--The origin and function of music.--The nebular hypothesis.--Bain on the emotions and the will.--Illogical geology.--The development hypothesis.--The social organism.--Use and beauty.--The sources of architectural types.--The use of anthropomorphism."
          # rubocop:enable Layout/LineLength
        }
      end

      it "re-joins using the delimiter" do
        # rubocop:disable Layout/LineLength
        expect(subject.to_s).to eq "Progress: its law and cause. -- Manners and fashion. -- The genesis of science. -- The physiology of laughter. -- The origin and function of music. -- The nebular hypothesis. -- Bain on the emotions and the will. -- Illogical geology. -- The development hypothesis. -- The social organism. -- Use and beauty. -- The sources of architectural types. -- The use of anthropomorphism."
        # rubocop:enable Layout/LineLength
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

  describe "#values" do
    context "with a non-TOC note" do
      # from druid:gx074xz5520
      let(:note) do
        {
          "value" => "Stanford University. Cabinet, Stanford University--Administration.",
          "type" => "preferred citation"
        }
      end

      it "leaves the values unchanged" do
        expect(subject.values).to eq ["Stanford University. Cabinet, Stanford University--Administration."]
      end
    end

    context "with a TOC with delimiters in the values" do
      # from druid:bm971cx9348
      let(:note) do
        {
          "structuredValue" => [
            {"value" => "-- pt.2. Abergavenny"},
            {"value" => "-- pt.5. Merthyr Tydfil --"}
          ],
          "type" => "table of contents",
          "displayLabel" => "Incomplete contents"
        }
      end

      it "returns the values with delimiters stripped out" do
        expect(subject.values).to eq ["pt.2. Abergavenny", "pt.5. Merthyr Tydfil"]
      end
    end

    context "with a TOC with delimiters in a single value" do
      # from druid:sw284bk0647
      let(:note) do
        {
          "type" => "table of contents",
          # rubocop:disable Layout/LineLength
          "value" => "Progress: its law and cause.--Manners and fashion.--The genesis of science.--The physiology of laughter.--The origin and function of music.--The nebular hypothesis.--Bain on the emotions and the will.--Illogical geology.--The development hypothesis.--The social organism.--Use and beauty.--The sources of architectural types.--The use of anthropomorphism."
          # rubocop:enable Layout/LineLength
        }
      end

      it "returns the values split on the delimiter" do
        expect(subject.values).to eq [
          "Progress: its law and cause.",
          "Manners and fashion.",
          "The genesis of science.",
          "The physiology of laughter.",
          "The origin and function of music.",
          "The nebular hypothesis.",
          "Bain on the emotions and the will.",
          "Illogical geology.",
          "The development hypothesis.",
          "The social organism.",
          "Use and beauty.",
          "The sources of architectural types.",
          "The use of anthropomorphism."
        ]
      end
    end
  end

  context "with a parallel transliterated TOC" do
    # adapted from druid:xx402cm3448
    # rubocop:disable Layout/LineLength
    let(:note) do
      {
        "parallelValue" => [
          {
            "value" => "Maps: -- [1] Generalʹnai͡a karta Rossīĭskoĭ Imperīi na sorokʺ odnu gubernīi͡u razdi͡elennoĭ -- [2] Karta S. Peterburgskoĭ gubernīi izʺ 7 ui͡ezdovʺ",
            "displayLabel" => "Partial contents"
          },
          {
            "value" => "Maps: -- [1] Генеральная карта Россійской Имперіи на сорокъ одну губернію раздѣленной -- [2] Карта С. Петербургской губерніи изъ 7 уѣздовъ"
          }
        ],
        "type" => "table of contents"
      }
    end

    it "renders itself using the first parallelValue" do
      expect(subject.to_s).to eq "Maps: -- [1] Generalʹnai͡a karta Rossīĭskoĭ Imperīi na sorokʺ odnu gubernīi͡u razdi͡elennoĭ -- [2] Karta S. Peterburgskoĭ gubernīi izʺ 7 ui͡ezdovʺ"
    end

    it "uses the values from the first parallelValue" do
      expect(subject.values[1]).to eq "[1] Generalʹnai͡a karta Rossīĭskoĭ Imperīi na sorokʺ odnu gubernīi͡u razdi͡elennoĭ"
    end

    it "links the values to their parallel versions" do
      expect(subject.main_value.siblings.first.values[1]).to eq "[1] Генеральная карта Россійской Имперіи на сорокъ одну губернію раздѣленной"
    end
    # rubocop:enable Layout/LineLength

    it "honors the displayLabel for the parallel values if rendered separately" do
      expect(subject.main_value.label).to eq "Partial contents"
    end

    it "generates displayLabel for parallel values if not set" do
      expect(subject.main_value.siblings.first.label).to eq "Table of contents"
    end
  end
end

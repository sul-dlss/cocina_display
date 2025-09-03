# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:cocina_json) do
    {
      "description" => {
        "language" => languages
      }
    }.to_json
  end
  let(:record) { described_class.from_json(cocina_json) }

  describe "#searchworks_language_names" do
    subject { record.searchworks_language_names }

    context "with no languages" do
      let(:languages) { [] }

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "with language with simple value" do
      let(:languages) do
        [
          {"value" => "English"}
        ]
      end

      it "returns the language" do
        expect(subject).to eq ["English"]
      end
    end

    context "with language with iso639 code and no value" do
      let(:languages) do
        [
          {"code" => "eng"}
        ]
      end

      it "returns the decoded language name" do
        expect(subject).to eq ["English"]
      end
    end

    context "with language with special searchworks code" do
      let(:languages) do
        [
          {"code" => "egy-Egyd"}
        ]
      end

      it "returns the decoded language name" do
        expect(subject).to eq ["Egyptian, Demotic"]
      end
    end

    context "with language with iso639 code that is not a Searchworks language" do
      let(:languages) do
        [
          {"code" => "zxx"} # maps to "No linguistic content"
        ]
      end

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "with a simple value that is not a Searchworks language" do
      let(:languages) do
        [
          {"value" => "Western Frisian"} # exists, but Searchworks calls it "Frisian"
        ]
      end

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "when a code and a value duplicate each other" do
      let(:languages) do
        [
          {"code" => "eng", "source" => {"code" => "iso639-2"}},
          {"value" => "English"}
        ]
      end

      it "deduplicates lanugage names" do
        expect(subject).to eq ["English"]
      end
    end
  end

  describe "#language_display_data" do
    subject { record.language_display_data }

    context "with no languages" do
      let(:languages) { [] }

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "with one language lacking a value" do
      let(:languages) do
        [
          {"value" => ""}
        ]
      end

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "with languages" do
      let(:languages) do
        [
          {"value" => "English"},
          {"value" => "Spanish"},
          {"value" => ""},
          {"code" => "eng", "source" => {"code" => "iso639-2"}},
          {"value" => "English"},
          {"code" => "zxx"},
          {"code" => "egy-Egyd"},
          {"value" => "Sumerian", "displayLabel" => "Primary language"}
        ]
      end

      it "returns display data for each language with duplicates removed" do
        expect(subject).to contain_exactly(
          be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Language", values: ["English", "Spanish", "Egyptian, Demotic"])),
          be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Primary language", values: ["Sumerian"]))
        )
      end
    end
  end
end

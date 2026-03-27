# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Titles::Title do
  subject { described_class.new(cocina_doc) }

  context "with parallel structured title values" do
    let(:cocina_doc) do
      {
        "parallelValue" => [
          {
            "structuredValue" => [
              {"value" => "ha-", "type" => "nonsorting characters"},
              {"value" => "Yeled ḥalom ", "type" => "main title"},
              {"value" => "maḥazeh be-arbaʻah ḥalaḳim ", "type" => "subtitle"}
            ],
            "type" => "transliterated"
          },
          {
            "structuredValue" => [
              {"value" => "ה", "type" => "nonsorting characters"},
              {"value" => "ילד חלום", "type" => "main title"},
              {"value" => "מחזה בארבעה חלקים", "type" => "subtitle"}
            ],
            "type" => "alternative"
          },
          {
            "structuredValue" => [
              {"value" => "The ", "type" => "nonsorting characters"},
              {"value" => "Child Dreams", "type" => "main title"},
              {"value" => "play in four parts", "type" => "subtitle"}
            ],
            "type" => "translated"
          }
        ]
      }
    end

    describe "#label" do
      it "uses the label of the main title value" do
        expect(subject.label).to eq "Alternative title"
      end
    end

    describe "#to_s" do
      it "uses the display version of the main title value" do
        expect(subject.to_s).to eq "הילד חלום : מחזה בארבעה חלקים"
      end
    end

    describe "#type" do
      it "uses the type of the main title value" do
        expect(subject.type).to eq "alternative"
      end
    end

    describe "#parallel_values" do
      it "returns all values except the main value" do
        expect(subject.parallel_values.map(&:to_s)).to eq [
          "ha-Yeled ḥalom : maḥazeh be-arbaʻah ḥalaḳim",
          "The Child Dreams : play in four parts"
        ]
      end
    end

    describe "#translated_value" do
      it "uses the translated title value" do
        expect(subject.translated_value.to_s).to eq "The Child Dreams : play in four parts"
      end
    end
    it { is_expected.to have_translation }

    describe "#transliterated_value" do
      it "uses the transliterated title value" do
        expect(subject.transliterated_value.to_s).to eq "ha-Yeled ḥalom : maḥazeh be-arbaʻah ḥalaḳim"
      end
    end
    it { is_expected.to have_transliteration }

    it "uses the type of the main value for the parallel values" do
      subject.parallel_values.each do |value|
        expect(value).to be_type
        expect(value.type).to eq "alternative"
      end
    end
  end

  context "with a transliterated title value that has a valueLanguage with a script" do
    let(:cocina_doc) do
      {
        "parallelValue" => [
          {
            "value" => "הילד חלום : מחזה בארבעה חלקים"
          },
          {
            "value" => "ha-Yeled ḥalom : maḥazeh be-arbaʻah ḥalaḳim",
            "valueLanguage" => {
              "code" => "heb",
              "valueScript" => {
                "code" => "Latn"
              }
            }
          }
        ]
      }
    end

    describe "#transliterated_value" do
      it "considers the value transliterated based on the script and language" do
        expect(subject.title_values[1]).to be_transliterated
      end
    end
  end
end

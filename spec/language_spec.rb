# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Languages::Language do
  subject { described_class.new(language) }

  describe "#label" do
    let(:language) do
      {"value" => "English"}
    end

    it "returns the label for language" do
      expect(subject.label).to eq "Language"
    end

    context "when displayLabel is set" do
      let(:language) do
        {
          "value" => "English",
          "displayLabel" => "Primary language"
        }
      end

      it "returns the displayLabel for language" do
        expect(subject.label).to eq "Primary language"
      end
    end
  end

  describe "#ietf_tag" do
    context "with no specified script" do
      let(:language) do
        {"code" => "eng", "source" => {"code" => "iso639-2"}}
      end

      it "returns the ISO639 code" do
        expect(subject.ietf_tag).to eq "eng"
      end
    end

    context "with a transliterated value" do
      # Arabic written in latin script
      let(:language) do
        {
          "code" => "ar",
          "source" => {
            "code" => "iso639-2"
          },
          "script" => {
            "code" => "Latn",
            "source" => {
              "code" => "iso15924"
            }
          }
        }
      end

      it "returns the full ISO15924 language tag" do
        expect(subject.ietf_tag).to eq "ar-Latn"
      end
    end
  end

  describe "#transliterated?" do
    context "with a transliterated value" do
      let(:language) do
        {
          "code" => "ar",
          "source" => {
            "code" => "iso639-2"
          },
          "script" => {
            "code" => "Latn",
            "source" => {
              "code" => "iso15924"
            }
          }
        }
      end

      it "returns true" do
        expect(subject).to be_transliterated
      end
    end

    context "with no script specified" do
      let(:language) do
        {"code" => "eng", "source" => {"code" => "iso639-2"}}
      end

      it "returns false" do
        expect(subject).not_to be_transliterated
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/cocina_display/dates/date_range"

RSpec.describe CocinaDisplay::Dates::DateRange do
  subject(:date_range) { described_class.from_cocina(cocina) }

  describe "construction" do
    let(:cocina) do
      {
        "structuredValue" => [
          {"value" => "2023-01-01", "type" => "start", "encoding" => {"code" => "edtf"}},
          {"value" => "2023-12-31", "type" => "end", "encoding" => {"code" => "edtf"}}
        ]
      }
    end

    it "is also possible using the Date.from_cocina method" do
      expect(CocinaDisplay::Dates::Date.from_cocina(cocina).value).to eq(date_range.value)
    end
  end

  describe "#sort_key" do
    let(:date_pairs) do
      [
        ["2023-01-01", "2023-01-02"],
        ["2022-10-30", "2023-01-01"],
        ["2023", "2023-01-01"],
        ["1902", "2045"],
        ["2022-10-30", "unparseable"],
        ["0455", "0496"]
      ]
    end
    let(:cocina_dates) do
      date_pairs.map do |pair|
        {
          "structuredValue" => [
            {"value" => pair[0], "type" => "start", "encoding" => {"code" => "edtf"}},
            {"value" => pair[1], "type" => "end", "encoding" => {"code" => "edtf"}}
          ]
        }
      end
    end
    let(:dates) { cocina_dates.map { |c| described_class.from_cocina(c) } }

    it "sorts dates correctly" do
      sorted_dates = dates.sort
      expect(sorted_dates.map(&:value)).to eq([
        ["0455", "0496"],
        ["1902", "2045"],
        ["2022-10-30", "unparseable"],
        ["2022-10-30", "2023-01-01"],
        ["2023", "2023-01-01"],
        ["2023-01-01", "2023-01-02"]
      ])
    end
  end

  describe "#encoding" do
    let(:cocina) do
      {
        "structuredValue" => [
          {"value" => "2023-01-01", "type" => "start", "encoding" => {"code" => "iso8601"}},
          {"value" => "2023-12-31", "type" => "end", "encoding" => {"code" => "marc"}}
        ]
      }
    end

    it "returns the encoding of the start date" do
      expect(date_range.encoding).to eq("iso8601")
    end

    context "when only the end date is present" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-12-31", "type" => "end", "encoding" => {"code" => "marc"}}
          ]
        }
      end

      it "returns the encoding of the end date" do
        expect(date_range.encoding).to eq("marc")
      end
    end

    context "when encoding is declared at the top level" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end"}
          ],
          "encoding" => {"code" => "edtf"}
        }
      end

      it "returns the top-level encoding" do
        expect(date_range.encoding).to eq("edtf")
      end
    end
  end

  describe "#qualified?" do
    context "when the start date is qualified" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start", "qualifier" => "questionable"},
            {"value" => "2023-12-31", "type" => "end"}
          ]
        }
      end

      it "returns true" do
        expect(date_range.qualified?).to be true
      end
    end

    context "when the end date is qualified" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end", "qualifier" => "inferred"}
          ]
        }
      end

      it "returns true" do
        expect(date_range.qualified?).to be true
      end
    end

    context "when neither date is qualified" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end"}
          ]
        }
      end

      it "returns false" do
        expect(date_range.qualified?).to be false
      end
    end

    context "when the range is qualified at the top level" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end"}
          ],
          "qualifier" => "approximate"
        }
      end

      it "returns true" do
        expect(date_range.qualified?).to be true
      end
    end
  end

  describe "#primary?" do
    context "when the start date is primary" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start", "status" => "primary"},
            {"value" => "2023-12-31", "type" => "end"}
          ]
        }
      end
      it "returns true" do
        expect(date_range.primary?).to be true
      end
    end

    context "when the end date is primary" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end", "status" => "primary"}
          ]
        }
      end

      it "returns true" do
        expect(date_range.primary?).to be true
      end
    end

    context "when neither date is primary" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end"}
          ]
        }
      end

      it "returns false" do
        expect(date_range.primary?).to be false
      end
    end

    context "when the range is marked as primary at the top level" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end"}
          ],
          "status" => "primary"
        }
      end

      it "returns true" do
        expect(date_range.primary?).to be true
      end
    end
  end

  describe "#parsed_date?" do
    context "when the start date is successfully parsed" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start"},
            {"value" => "unparseable", "type" => "end"}
          ]
        }
      end

      it "returns true" do
        expect(date_range.parsed_date?).to be true
      end
    end

    context "when the end date is successfully parsed" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "unparseable", "type" => "start"},
            {"value" => "2023-12-31", "type" => "end"}
          ]
        }
      end

      it "returns true" do
        expect(date_range.parsed_date?).to be true
      end
    end

    context "when neither date is successfully parsed" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "unparseable", "type" => "start"},
            {"value" => "unparseable", "type" => "end"}
          ]
        }
      end

      it "returns false" do
        expect(date_range.parsed_date?).to be false
      end
    end
  end

  describe "#decoded_value" do
    let(:cocina) do
      {
        "structuredValue" => [
          {"value" => "2023-01-01", "type" => "start", "encoding" => {"code" => "iso8601"}},
          {"value" => "2023-12-31", "type" => "end", "encoding" => {"code" => "iso8601"}}
        ]
      }
    end

    it "returns the decoded values joined together" do
      expect(date_range.decoded_value).to eq("January  1, 2023 - December 31, 2023")
    end
  end

  describe "#qualified_value" do
    context "when both dates have matching qualifiers" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start", "qualifier" => "approximate", "encoding" => {"code" => "iso8601"}},
            {"value" => "2023-12-31", "type" => "end", "qualifier" => "approximate", "encoding" => {"code" => "iso8601"}}
          ]
        }
      end

      it "returns the qualified value for the range" do
        expect(date_range.qualified_value).to eq("[ca. January  1, 2023 - December 31, 2023]")
      end
    end

    context "when the start and end dates have different qualifiers" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start", "qualifier" => "approximate", "encoding" => {"code" => "iso8601"}},
            {"value" => "2023-12-31", "type" => "end", "qualifier" => "inferred", "encoding" => {"code" => "iso8601"}}
          ]
        }
      end

      it "returns the qualified value for the range" do
        expect(date_range.qualified_value).to eq("[ca. January  1, 2023] - [December 31, 2023]")
      end
    end

    context "when neither date has a qualifier" do
      let(:cocina) do
        {
          "structuredValue" => [
            {"value" => "2023-01-01", "type" => "start", "encoding" => {"code" => "iso8601"}},
            {"value" => "2023-12-31", "type" => "end", "encoding" => {"code" => "iso8601"}}
          ]
        }
      end

      it "returns the decoded value without qualifiers" do
        expect(date_range.qualified_value).to eq("January  1, 2023 - December 31, 2023")
      end
    end
  end
end

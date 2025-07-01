# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:dates) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "event" => [
          {"date" => dates}
        ]
      }
    }.to_json
  end
  let(:record) { described_class.new(cocina_json) }
  let(:ignore_qualified) { false }

  describe "#pub_year_display_str" do
    subject { record.pub_year_display_str(ignore_qualified: ignore_qualified) }

    context "when there are no dates" do
      it { is_expected.to be_nil }
    end

    context "when there are no dates with a valid type" do
      let(:dates) do
        [
          {"value" => "2020", "type" => "acquisition"},
          {"value" => "2021", "type" => "deposit"}
        ]
      end

      it { is_expected.to be_nil }
    end

    context "when there are no parsable dates" do
      let(:dates) { [{"value" => "invalid-date", "type" => "publication"}] }

      it { is_expected.to be_nil }
    end

    context "when the event has a valid type but the date has none" do
      let(:dates) { [{"value" => "2020"}] }
      let(:cocina_json) do
        {
          "description" => {
            "event" => [
              {"type" => "publication", "date" => dates}
            ]
          }
        }.to_json
      end

      it "treats the date as valid" do
        is_expected.to eq("2020")
      end
    end

    context "when there are multiple dates with different valid types" do
      let(:dates) do
        [
          {"value" => "2020", "type" => "publication"},
          {"value" => "2019", "type" => "creation"} # publication takes precedence
        ]
      end

      it "returns the earliest date in the preferred type" do
        is_expected.to eq("2020")
      end
    end

    context "when ignore_qualified is true" do
      let(:ignore_qualified) { true }

      let(:dates) do
        [
          {"value" => "2020", "type" => "publication", "qualifier" => "approximate"},
          {"value" => "2019", "type" => "creation"}
        ]
      end

      it "does not consider qualified dates" do
        is_expected.to eq("2019")
      end
    end

    context "when a date is marked as primary" do
      let(:dates) do
        [
          {"value" => "2019", "type" => "publication"},
          {"value" => "2020", "type" => "publication", "status" => "primary"},
          {"value" => "2021", "type" => "publication"}
        ]
      end

      it "returns the primary date" do
        is_expected.to eq("2020")
      end
    end

    context "when a date has a declared encoding" do
      let(:dates) do
        [
          {"value" => "2020-10-01", "type" => "publication", "encoding" => {"code" => "iso8601"}},
          {"value" => "sometime around 2019", "type" => "publication"}
        ]
      end

      it "uses the date with the declared encoding" do
        is_expected.to eq("2020")
      end
    end

    context "with a decade date (209x)" do
      let(:dates) do
        [
          {"value" => "209x", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq("2090s") }
    end

    context "with a century date (20xx)" do
      let(:dates) do
        [
          {"value" => "20xx", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq("21st century") }
    end

    context "with a BCE date (5 BCE)" do
      let(:dates) do
        [
          {"value" => "-0005", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq("6 BCE") }
    end

    context "with a date range (2020-01-01 to 2021-10-31)" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2020-01-01", "type" => "start", "encoding" => {"code" => "w3cdtf"}},
              {"value" => "2021-10-31", "type" => "end", "encoding" => {"code" => "w3cdtf"}}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq("2020 - 2021") }
    end
  end

  describe "#pub_year_int" do
    subject { record.pub_year_int }

    context "with a valid date with year (2020)" do
      let(:dates) do
        [
          {"value" => "2020", "type" => "publication"}
        ]
      end

      it { is_expected.to eq(2020) }
    end

    context "with a decade date (209x)" do
      let(:dates) do
        [
          {"value" => "209x", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq(2090) }
    end

    context "with a century date (20xx)" do
      let(:dates) do
        [
          {"value" => "20xx", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq(2000) }
    end

    context "with a date range (2020-01-01 to 2021-10-31)" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2020-01-01", "type" => "start", "encoding" => {"code" => "w3cdtf"}},
              {"value" => "2021-10-31", "type" => "end", "encoding" => {"code" => "w3cdtf"}}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq(2020) }
    end

    context "with an EDTF interval (6 BCE to 5 BCE)" do
      let(:dates) do
        [
          {
            "value" => "-0005/-0004", "type" => "publication", "encoding" => {"code" => "edtf"}
          }
        ]
      end

      it { is_expected.to eq(-5) }
    end
  end
end

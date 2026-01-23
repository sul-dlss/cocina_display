# frozen_string_literal: true

require "spec_helper"

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
  let(:record) { described_class.from_json(cocina_json) }
  let(:ignore_qualified) { false }

  describe "#pub_year_str" do
    subject { record.pub_year_str(ignore_qualified: ignore_qualified) }

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

    context "when both the event and date have valid types" do
      let(:cocina_json) do
        {
          "description" => {
            "event" => [
              {
                "type" => "publication",
                "date" => [
                  {"value" => "2022", "type" => "publication"}
                ]
              }
            ]
          }
        }.to_json
      end

      it "returns the publication date" do
        is_expected.to eq("2022")
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

    context "with a marc range with unknown start" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "uuuu", "type" => "start"},
              {"value" => "1868", "type" => "end"}
            ],
            "type" => "publication",
            "encoding" => {"code" => "marc"},
            "qualifier" => "questionable"
          }
        ]
      end

      it { is_expected.to eq(1868) }
    end

    context "with a date range with no start" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "1948", "type" => "end", "status" => "primary"}
            ],
            "type" => "creation",
            "encoding" => {"code" => "w3cdtf"},
            "qualifier" => "approximate"
          }
        ]
      end

      it { is_expected.to eq(1948) }
    end

    context "with a date range with no end" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2001", "type" => "start", "status" => "primary"}
            ],
            "type" => "creation",
            "encoding" => {"code" => "w3cdtf"},
            "qualifier" => "approximate"
          }
        ]
      end

      it { is_expected.to eq(2001) }
    end
  end

  describe "#pub_year_int_range" do
    subject { record.pub_year_int_range }

    context "with a valid date range (2020-01-01 to 2021-10-31)" do
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

      it { is_expected.to eq([2020, 2021]) }
    end

    context "with an EDTF interval (6 BCE to 5 BCE)" do
      let(:dates) do
        [
          {
            "value" => "-0005/-0004", "type" => "publication", "encoding" => {"code" => "edtf"}
          }
        ]
      end

      it { is_expected.to eq([-5, -4]) }
    end

    context "with a single year date (2020)" do
      let(:dates) do
        [
          {"value" => "2020", "type" => "publication"}
        ]
      end

      it { is_expected.to eq([2020]) }
    end

    context "with a decade date (209x)" do
      let(:dates) do
        [
          {"value" => "209x", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq([2090, 2091, 2092, 2093, 2094, 2095, 2096, 2097, 2098, 2099]) }
    end

    context "with an invalid date" do
      let(:dates) do
        [
          {"value" => "invalid-date", "type" => "publication"}
        ]
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#imprint_str" do
    subject { record.imprint_str }

    let(:cocina_json) do
      {
        "description" => {
          "event" => events
        }
      }.to_json
    end

    context "with multiple events, single imprint" do
      # from druid:bm971cx9348
      let(:events) do
        [
          {
            "date" => [
              {
                "structuredValue" => [
                  {"value" => "1920", "type" => "start"}
                ],
                "type" => "publication",
                "encoding" => {"code" => "marc"}
              }
            ],
            "location" => [
              {"code" => "enk", "source" => {"code" => "marccountry"}}
            ],
            "note" => [
              {"type" => "issuance", "value" => "monographic", "source" => {"value" => "MODS issuance terms"}}
            ]
          },
          {
            "date" => [
              {"value" => "[192-?]-[193-?]", "type" => "publication"}
            ],
            "note" => [
              {"type" => "edition", "value" => "2nd ed."}
            ],
            "contributor" => [
              {
                "name" => [
                  {"value" => "H.M. Stationery Off."}
                ],
                "role" => [
                  {
                    "value" => "publisher",
                    "code" => "pbl",
                    "uri" => "http://id.loc.gov/vocabulary/relators/pbl",
                    "source" => {
                      "code" => "marcrelator",
                      "uri" => "http://id.loc.gov/vocabulary/relators/"
                    }
                  }
                ],
                "type" => "organization"
              }
            ],
            "location" => [
              {"value" => "London"},
              {"source" => {"code" => "marccountry"}, "code" => "enk"}
            ]
          }
        ]
      end

      it "renders the imprint statement" do
        is_expected.to eq "2nd ed. - London : H.M. Stationery Off., [192-?]-[193-?]"
      end
    end
  end

  describe "#publication_places" do
    subject { record.publication_places }

    let(:cocina_json) do
      {
        "description" => {
          "event" => events
        }
      }.to_json
    end

    context "with publication event with unencoded location" do
      let(:events) do
        [
          {
            "date" => [
              {"value" => "[192-?]-[193-?]", "type" => "publication"}
            ],
            "location" => [
              {"value" => "London"}
            ]
          }
        ]
      end

      it { is_expected.to eq ["London"] }
    end

    context "with publication event with an encoded location" do
      let(:events) do
        [
          {
            "date" => [
              {"value" => "[192-?]-[193-?]", "type" => "publication"}
            ],
            "location" => [
              {"source" => {"code" => "marccountry"}, "code" => "enk"}
            ]
          }
        ]
      end

      it { is_expected.to eq ["England"] }
    end

    context "with event locations that are not publication" do
      let(:events) do
        [
          {
            "date" => [
              {"value" => "1921", "type" => "assembly"}
            ],
            "location" => [
              {"value" => "London"}
            ]
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#publication_countries" do
    subject { record.publication_countries }

    let(:cocina_json) do
      {
        "description" => {
          "event" => events
        }
      }.to_json
    end

    context "with publication event with unencoded location" do
      let(:events) do
        [
          {
            "date" => [
              {"value" => "[192-?]-[193-?]", "type" => "publication"}
            ],
            "location" => [
              {"value" => "London"}
            ]
          }
        ]
      end

      it { is_expected.to eq [] }
    end

    context "with publication event with an encoded location" do
      let(:events) do
        [
          {
            "date" => [
              {"value" => "[192-?]-[193-?]", "type" => "publication"}
            ],
            "location" => [
              {"source" => {"code" => "marccountry"}, "code" => "enk"}
            ]
          }
        ]
      end

      it { is_expected.to eq ["England"] }
    end
  end

  describe "#admin_creation_event" do
    subject { record.admin_creation_event }

    let(:cocina_json) do
      <<~JSON
        {
          "description": {
            "adminMetadata": {
              "event": [
                {
                  "type": "creation",
                  "date": [
                    {
                      "value": "2023-09-14",
                      "encoding": {
                        "code": "edtf"
                      }
                    }
                  ]
                }
              ],
              "note": [
                {
                  "value": "Metadata created by user via Stanford self-deposit application",
                  "type": "record origin"
                }
              ]
            }
          }
        }
      JSON
    end

    it { is_expected.to be_a(CocinaDisplay::Events::Event) }
  end

  describe "#event_note_display_data" do
    let(:cocina_json) do
      {
        "description" => {
          "event" => [
            {"note" => [{"value" => "monographic", "type" => "issuance"}, {"value" => "[Warwickshire ed.]", "type" => "edition"}], "type" => "publication"}
          ]
        }
      }.to_json
    end

    subject { record.event_note_display_data }

    it "returns the note display data" do
      expect(subject).to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(
          have_attributes(label: "Issuance", values: ["monographic"])
        ),
        be_a(CocinaDisplay::DisplayData).and(
          have_attributes(label: "Edition", values: ["[Warwickshire ed.]"])
        )
      )
    end
  end

  describe "#event_date_display_data" do
    let(:cocina_json) do
      {
        "description" => {
          "event" => [
            {
              "date" => [
                {
                  "structuredValue" => [
                    {
                      "value" => "1758",
                      "type" => "start"
                    },
                    {
                      "value" => "uuuu",
                      "type" => "end"
                    }
                  ],
                  "type" => "publication",
                  "encoding" => {
                    "code" => "marc"
                  },
                  "qualifier" => "questionable"
                }
              ]
            },
            {
              "date" => [{"value" => "invalid-date", "type" => "production"}] # left alone
            },
            {
              "date" => [{"type" => "copyright", "value" => "-0099", "encoding" => {"code" => "edtf"}}]
            },
            {
              "date" => [{"value" => "199x", "encoding" => {"code" => "edtf"}, "displayLabel" => "Fictional date"}]
            },
            {
              "date" => [{"value" => "2021"}]
            }
          ]
        }
      }.to_json
    end

    subject { CocinaDisplay::DisplayData.to_hash(record.event_date_display_data) }

    it "groups by label and returns the display value for the date" do
      expect(subject).to eq(
        {
          "Publication date" => ["[1758 - Unknown?]"],
          "Production date" => ["invalid-date"],
          "Copyright date" => ["100 BCE"],
          "Fictional date" => ["1990s"],
          "Date" => ["2021"]
        }
      )
    end
  end
end

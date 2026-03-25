# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:dates) { [] }
  let(:cocina) do
    {
      "description" => {
        "event" => [
          {"date" => dates}
        ]
      }
    }
  end
  let(:record) { described_class.new(cocina) }
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
      let(:cocina) do
        {
          "description" => {
            "event" => [
              {"type" => "publication", "date" => dates}
            ]
          }
        }
      end

      it "treats the date as valid" do
        is_expected.to eq("2020")
      end
    end

    context "when both the event and date have valid types" do
      let(:cocina) do
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
        }
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

    context "with a date value embedded in running text" do
      let(:dates) do
        [
          {"value" => "view of approximately 1848, published about 1865", "type" => "publication"}
        ]
      end

      it { is_expected.to eq("1848") }
    end

    context "with an unparsable date" do
      let(:dates) do
        [
          {"value" => "not a date", "type" => "publication"}
        ]
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#pub_date_str" do
    subject { record.pub_date_str }

    context "with a year" do
      let(:dates) do
        [
          {"value" => "2020", "type" => "publication"}
        ]
      end

      it { is_expected.to eq("2020") }
    end

    context "with a decade date (209x)" do
      let(:dates) do
        [
          {"value" => "209x", "type" => "publication", "encoding" => {"code" => "edtf"}}
        ]
      end

      it { is_expected.to eq("2090s") }
    end

    context "with an encoded date range (2020-01-01 to 2021-10-31)" do
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

      it { is_expected.to eq("January 1, 2020 - October 31, 2021") }
    end

    context "with an open-ended range" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2000", "type" => "start"}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq("2000 -") }
    end

    context "with a date value embedded in running text" do
      let(:dates) do
        [
          {"value" => "view of approximately 1848, published about 1865", "type" => "publication"}
        ]
      end

      it { is_expected.to eq("view of approximately 1848, published about 1865") }
    end

    context "with an unparsable date" do
      let(:dates) do
        [
          {"value" => "not a date", "type" => "publication"}
        ]
      end

      it { is_expected.to be_nil }
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

  describe "#pub_year_ints" do
    subject { record.pub_year_ints }

    context "with a start and end with day precision" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2020-01-01", "type" => "start", "encoding" => {"code" => "w3cdtf"}},
              {"value" => "2022-10-31", "type" => "end", "encoding" => {"code" => "w3cdtf"}}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq([2020, 2021, 2022]) }
    end

    context "with a start and end with year precision" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "1200", "type" => "start", "encoding" => {"code" => "marc"}},
              {"value" => "1299", "type" => "end", "encoding" => {"code" => "marc"}}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq((1200..1299).to_a) }
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

    # NOTE: currently doesn't exist in SDR, but valid EDTF
    context "with an EDTF interval (month precision)" do
      let(:dates) do
        [
          {
            "value" => "1984-06/2004-08", "type" => "publication", "encoding" => {"code" => "edtf"}
          }
        ]
      end

      it { is_expected.to eq((1984..2004).to_a) }
    end

    # NOTE: currently doesn't exist in SDR, but valid EDTF
    context "with EDTF set intersection" do
      let(:dates) do
        [
          {
            "value" => "{1667,1668,1670..1672}", "type" => "publication", "encoding" => {"code" => "edtf"}
          }
        ]
      end

      it { is_expected.to eq([1667, 1668, 1670, 1671, 1672]) }
    end

    # NOTE: currently doesn't exist in SDR, but valid EDTF
    context "with date range including an interval" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "1667", "type" => "start", "encoding" => {"code" => "edtf"}},
              {"value" => "1670/1672", "type" => "end", "encoding" => {"code" => "edtf"}}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq([1667, 1670, 1671, 1672]) }
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

    context "with an end date and open start date" do
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

      it "uses the end date" do
        is_expected.to eq([1948])
      end
    end

    context "with a start date and open end date" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2000", "type" => "start"}
            ],
            "type" => "publication"
          }
        ]
      end

      it "extends the range to the current year" do
        is_expected.to eq((2000..Date.today.year).to_a)
      end
    end

    context "with an unknown end date" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "2000", "type" => "start"},
              {"value" => "uuuu", "type" => "end"}
            ],
            "type" => "publication",
            "encoding" => {"code" => "marc"},
            "qualifier" => "questionable"
          }
        ]
      end

      it "extends the range to the current year" do
        is_expected.to eq((2000..Date.today.year).to_a)
      end
    end

    context "with an unknown start date" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "uuuu", "type" => "start"},
              {"value" => "2000", "type" => "end"}
            ],
            "type" => "publication",
            "encoding" => {"code" => "marc"},
            "qualifier" => "questionable"
          }
        ]
      end

      it "uses only the known year" do
        is_expected.to eq([2000])
      end
    end
  end

  describe "#pub_date_sort_str" do
    subject { record.pub_date_sort_str(ignore_qualified: ignore_qualified) }

    context "with a single CE year" do
      let(:dates) do
        [{"value" => "2020", "type" => "publication"}]
      end

      it { is_expected.to eq("20200000") }
    end

    context "with a day range (2020-01-01 to 2021-10-31)" do
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

      it { is_expected.to eq("2020010120211031") }
    end

    context "with a BCE year range" do
      let(:dates) do
        [
          {
            "structuredValue" => [
              {"value" => "-3500", "type" => "start", "encoding" => {"code" => "edtf"}},
              {"value" => "-3101", "type" => "end", "encoding" => {"code" => "edtf"}}
            ],
            "type" => "publication"
          }
        ]
      end

      it { is_expected.to eq("-564990000-568980000") }
    end
  end

  describe "#imprint_str" do
    subject { record.imprint_str }

    let(:cocina) do
      {
        "description" => {
          "event" => events
        }
      }
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

    let(:cocina) do
      {
        "description" => {
          "event" => events
        }
      }
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

    let(:cocina) do
      {
        "description" => {
          "event" => events
        }
      }
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

    let(:cocina) do
      {
        "description" => {
          "adminMetadata" => {
            "event" => [
              {
                "type" => "creation",
                "date" => [
                  {
                    "value" => "2023-09-14",
                    "encoding" => {
                      "code" => "edtf"
                    }
                  }
                ]
              }
            ],
            "note" => [
              {
                "value" => "Metadata created by user via Stanford self-deposit application",
                "type" => "record origin"
              }
            ]
          }
        }
      }
    end

    it { is_expected.to be_a(CocinaDisplay::Events::Event) }
  end

  describe "#event_note_display_data" do
    subject { CocinaDisplay::DisplayData.to_hash(record.event_note_display_data) }

    let(:cocina) do
      {
        "description" => {
          "event" => [
            {
              "note" => [
                {"value" => "Monographic", "type" => "issuance"},
                {"value" => "Weekly", "type" => "frequency"},
                {"value" => "[Warwickshire ed.]", "type" => "edition"},
                {"value" => "c2019", "type" => "copyright statement"}
              ],
              "type" => "publication"
            }
          ]
        }
      }
    end

    it "lowercases issuance and frequency notes" do
      is_expected.to eq({
        "Issuance" => ["monographic"],
        "Frequency" => ["weekly"],
        "Edition" => ["[Warwickshire ed.]"],
        "Copyright statement" => ["c2019"]
      })
    end
  end

  describe "#event_display_data" do
    subject { CocinaDisplay::DisplayData.to_hash(record.event_display_data) }

    context "with events that only have dates" do
      let(:cocina) do
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
              }
            ]
          }
        }
      end

      it "uses date labels and display labels to group content" do
        expect(subject).to eq(
          {
            "Publication date" => ["[1758 - Unknown?]"],
            "Production date" => ["invalid-date"],
            "Copyright date" => ["100 BCE"],
            "Fictional date" => ["1990s"]
          }
        )
      end
    end

    context "with events that include notes" do
      # from druid:zf208gz2565
      let(:cocina) do
        {
          "description" => {
            "event" => [
              {
                "date" => [
                  {
                    "value" => "1866-02-22",
                    "type" => "publication",
                    "status" => "primary",
                    "encoding" => {
                      "code" => "w3cdtf"
                    }
                  }
                ],
                "location" => [
                  {
                    "code" => "nyu",
                    "source" => {
                      "code" => "marccountry"
                    }
                  }
                ],
                "note" => [
                  {
                    "value" => "serial",
                    "type" => "issuance",
                    "source" => {
                      "value" => "MODS issuance terms"
                    }
                  },
                  {
                    "value" => "Weekly",
                    "type" => "frequency"
                  }
                ]
              },
              {
                "contributor" => [
                  {
                    "name" => [
                      {
                        "value" => "Street and Smith"
                      }
                    ],
                    "type" => "organization",
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
                    ]
                  }
                ],
                "location" => [
                  {
                    "value" => "New York, N.Y."
                  }
                ]
              }
            ]
          }
        }
      end

      it "uses the date/event type as the heading and includes notes in the value" do
        is_expected.to eq(
          {
            "Publication" => ["New York (State), February 22, 1866"],
            "Imprint" => ["New York, N.Y. : Street and Smith"]
          }
        )
      end
    end

    context "with an imprint" do
      let(:cocina) do
        {
          "description" => {
            "event" => [
              {
                "date" => [
                  {"value" => "[192-?]-[193-?]", "type" => "publication"}
                ],
                "location" => [
                  {"value" => "London"}
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
                ]
              }
            ]
          }
        }
      end

      it "returns the imprint under an imprint heading" do
        expect(subject).to eq(
          {
            "Imprint" => ["London : H.M. Stationery Off., [192-?]-[193-?]"]
          }
        )
      end
    end

    context "with an event with displayLabel" do
      # adapted from druid:cj555pv1585
      let(:cocina) do
        {
          "description" => {
            "event" => [
              {
                "displayLabel" => "Court location and trial date",
                "date" => [
                  {
                    "structuredValue" => [
                      {"value" => "02/06/1946", "type" => "start"},
                      {"value" => "03/22/1946", "type" => "end"}
                    ],
                    "displayLabel" => "Date of case active"
                  }
                ],
                "location" => [
                  {
                    "value" => "Ludwigsberg (Germany)",
                    "type" => "capture",
                    "uri" => "http://id.loc.gov/authorities/names/n81058988"
                  }
                ]
              }
            ]
          }
        }
      end

      it "uses the event displayLabel as the heading" do
        expect(subject).to eq(
          {
            "Court location and trial date" => ["Ludwigsberg (Germany), 02/06/1946 - 03/22/1946"]
          }
        )
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Events::Imprint do
  subject { described_class.new(cocina).to_s }

  describe "date processing" do
    context "with values marked as unparsable" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "9999", "type" => "publication"},
            {"value" => "2020", "type" => "publication"}
          ]
        }
      end

      it "skips those dates" do
        is_expected.to eq "2020"
      end
    end

    context "with several date types and formats" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "17uu", "type" => "publication", "encoding" => {"code" => "edtf"}},
            {"value" => "no date here", "type" => "creation"},
            {"value" => "1920-09", "type" => "capture", "encoding" => {"code" => "w3cdtf"}}
          ]
        }
      end

      it "concatenates all valid dates" do
        is_expected.to eq "no date here 18th century September 1920"
      end
    end

    context "with a mix of unencoded and encoded dates" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1920", "type" => "publication", "encoding" => {"code" => "edtf"}},
            {"value" => "1920]", "type" => "publication"}
          ]
        }
      end

      it "prefers the unencoded date to preserve punctuation-as-metadata" do
        is_expected.to eq "1920]"
      end
    end

    context "when there are duplicate dates" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1920", "type" => "publication", "encoding" => {"code" => "edtf"}},
            {"value" => "1920", "type" => "publication", "encoding" => {"code" => "marc"}},
            {"value" => "1920", "type" => "publication"}
          ]
        }
      end

      it "deduplicates them" do
        is_expected.to eq "1920"
      end
    end

    context "with a date range" do
      let(:cocina) do
        {
          "date" => [
            {
              "structuredValue" => [
                {"value" => "1920", "type" => "start"},
                {"value" => "1921", "type" => "end"}
              ],
              "encoding" => {"code" => "marc"},
              "type" => "publication"
            }
          ]
        }
      end

      it "renders the range" do
        is_expected.to eq "1920 - 1921"
      end
    end
  end

  describe "location processing" do
    context "when there is only a MARC country code available" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1921", "type" => "publication"}
          ],
          "location" => [
            {"source" => {"code" => "marccountry"}, "code" => "enk"}
          ]
        }
      end

      it "decodes the country code" do
        is_expected.to eq "England, 1921"
      end
    end

    context "with the country code xx" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1921", "type" => "publication"}
          ],
          "location" => [
            {"source" => {"code" => "marccountry"}, "code" => "xx"}
          ]
        }
      end

      it "ignores the place name" do
        is_expected.to eq "1921"
      end
    end

    context "with unencoded and encoded place names" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1921", "type" => "publication"}
          ],
          "location" => [
            {"value" => "London"},
            {"source" => {"code" => "marccountry"}, "code" => "enk"}
          ]
        }
      end

      it "prefers the unencoded place name" do
        is_expected.to eq "London, 1921"
      end
    end

    context "with duplicate place names" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1921", "type" => "publication"}
          ],
          "location" => [
            {"source" => {"code" => "marccountry"}, "code" => "enk"},
            {"source" => {"code" => "marccountry"}, "code" => "enk"}
          ]
        }
      end

      it "deduplicates the place names" do
        is_expected.to eq "England, 1921"
      end
    end

    context "with valid and invalid country codes" do
      let(:cocina) do
        {
          "date" => [
            {"value" => "1921", "type" => "publication"}
          ],
          "location" => [
            {"source" => {"code" => "marccountry"}, "code" => "xx"},
            {"source" => {"code" => "marccountry"}, "code" => "enk"},
            {"source" => {"code" => "marccountry"}, "code" => "oops"},
            {"source" => {"code" => "marccountry"}, "code" => "vp"}
          ]
        }
      end

      it "ignores the invalid codes" do
        is_expected.to eq "England, 1921"
      end
    end
  end

  context "with a publication place and date" do
    let(:cocina) do
      {
        "date" => [
          {"value" => "1921", "type" => "publication"}
        ],
        "location" => [
          {"value" => "London"}
        ]
      }
    end

    it "renders everything correctly" do
      is_expected.to eq "London, 1921"
    end
  end

  context "with a publisher and date" do
    let(:cocina) do
      {
        "date" => [
          {"value" => "1921.", "type" => "publication"}
        ],
        "contributor" => [
          {
            "name" => [{"value" => "Chronicle Books"}],
            "role" => [{"value" => "publisher"}]
          }
        ]
      }
    end

    it "renders everything correctly" do
      is_expected.to eq "Chronicle Books, 1921."
    end
  end

  context "with multiple publication places" do
    let(:cocina) do
      {
        "date" => [
          {"value" => "1921.", "type" => "publication"}
        ],
        "location" => [
          {"value" => "London"},
          {"value" => "England"}
        ]
      }
    end

    it "renders everything correctly" do
      is_expected.to eq "London : England, 1921."
    end
  end

  context "with a place, publisher, and date" do
    # from druid:bg262qk2288
    let(:cocina) do
      {
        "date" => [
          {"value" => "[1862]-", "type" => "publication"}
        ],
        "contributor" => [
          {
            "name" => [
              {"value" => "Librairie administrative de P. Dupont"}
            ],
            "type" => "organization",
            "role" => [
              {
                "value" => "publisher",
                "code" => "pbl",
                "uri" => "http://id.loc.gov/vocabulary/relators/pbl",
                "source" => {"code" => "marcrelator", "uri" => "http://id.loc.gov/vocabulary/relators/"}
              }
            ]
          }
        ],
        "location" => [
          {"value" => "Paris"}
        ]
      }
    end

    it "renders everything correctly" do
      # MARC may have had a comma after the place, but Cocina does not include it
      is_expected.to eq "Paris : Librairie administrative de P. Dupont, [1862]-"
    end
  end

  context "with an edition, publisher, place, and date" do
    # adapted from druid:bm971cx9348
    let(:cocina) do
      {
        "type" => "publication",
        "date" => [
          {"value" => "[192-?]-[193-?]", "type" => "publication"},
          {"structuredValue" => [{"value" => "1920", "type" => "start"}], "encoding" => {"code" => "marc"}, "type" => "publication"}
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
    end

    it "renders everything correctly" do
      # Prefers the unencoded place name and date
      is_expected.to eq "2nd ed. - London : H.M. Stationery Off., [192-?]-[193-?]"
    end
  end
end

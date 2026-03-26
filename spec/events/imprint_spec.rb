# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Events::Imprint do
  subject(:imprint) { described_class.new(cocina) }

  describe "#to_s" do
    subject { imprint.to_s }

    describe "date processing" do
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

        it "concatenates and orders all dates, respecting original value" do
          is_expected.to eq "no date here; 18th century; September 1920"
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

      # from druid:zs247rr8237
      context "with two distinct dates" do
        let(:cocina) do
          {
            "date" => [
              {
                "value" => "1674",
                "type" => "creation",
                "status" => "primary",
                "qualifier" => "approximate"
              },
              {
                "structuredValue" => [
                  {
                    "value" => "1690",
                    "type" => "end"
                  }
                ],
                "type" => "creation",
                "encoding" => {
                  "code" => "w3cdtf"
                },
                "qualifier" => "approximate"
              }
            ],
            "location" => [
              {
                "value" => "[Italy?]"
              }
            ]
          }
        end

        it "lists them separately, in order" do
          is_expected.to eq "[Italy?], [ca. 1674]; [ca. - 1690]"
        end
      end
    end

    describe "location processing" do
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

      it "separates using a colon" do
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
end

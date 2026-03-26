# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Events::Event do
  subject(:event) { described_class.new(cocina) }

  describe "#dates" do
    subject(:dates) { event.dates }

    # See also https://github.com/sul-dlss/cocina-models/issues/830
    context "with missing date value (as seen in wf027xk3554)" do
      before do
        allow(CocinaDisplay).to receive(:notifier).and_return(notifier)
      end

      let(:notifier) { double(:notifier, notify: nil) }

      let(:cocina) do
        {
          "date" => [
            {
              "encoding" => {
                "code" => "marc"
              }
            }
          ],
          "type" => "creation"
        }
      end

      it "removes the invalid date values" do
        expect(dates).to eq []
        expect(notifier).not_to have_received(:notify).with("Invalid date value")
      end
    end
  end

  describe "#to_s" do
    subject { event.to_s }

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

        it "concatenates and orders all dates" do
          is_expected.to eq "Unknown, 18th century, and September 1920"
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

        it "prefers the encoded date for clarity" do
          is_expected.to eq "1920"
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

        it "uses all place names" do
          is_expected.to eq "London, England, 1921"
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
  end

  describe "sorting" do
    let(:events) do
      [
        {"date" => [{"structuredValue" => [{"value" => "1920", "type" => "start"}, {"value" => "1930", "type" => "end"}]}]},
        {"date" => [{"value" => "-3099", "encoding" => {"code" => "edtf"}}]},
        {"date" => [{"value" => "1920-02-03", "encoding" => {"code" => "edtf"}}]},
        {"date" => [{"value" => "1920"}]},
        {"date" => [{"structuredValue" => [{"value" => "-3499", "type" => "start"}, {"value" => "-3100", "type" => "end"}], "encoding" => {"code" => "edtf"}}]}
      ].map { |cocina| described_class.new(cocina) }
    end

    subject { events.sort.map(&:to_s) }

    it "sorts events by their dates" do
      is_expected.to eq [
        "3500 BCE - 3101 BCE",
        "3100 BCE",
        "1920",
        "1920 - 1930",
        "February 3, 1920"
      ]
    end
  end

  describe "comparison" do
    let(:event1) { described_class.new("date" => [{"value" => "1920"}]) }
    let(:event2) { described_class.new("date" => [{"value" => "1920"}]) }
    let(:event3) { described_class.new("date" => [{"value" => "1921"}]) }
    let(:event4) { described_class.new("date" => [{"value" => "1930"}]) }

    it "considers events with the same date as equal" do
      expect(event1).to eq event2
    end

    it "supports #between?" do
      expect(event3).to be_between(event1, event4)
    end
  end
end

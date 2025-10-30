# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Dates::Date do
  subject(:date) { described_class.from_cocina(cocina) }

  describe "initialize" do
    # See also https://github.com/sul-dlss/cocina-models/issues/830
    context "with missing marc data (as seen in wf027xk3554)" do
      let(:cocina) do
        {
          "encoding" => {
            "code" => "marc"
          }
        }
      end

      it "does not raise an error" do
        expect { date }.not_to raise_error
      end
    end

    context "with missing w3cdtf data (as seen in gg897rh6063)" do
      let(:cocina) do
        {
          "encoding" => {
            "code" => "w3cdtf"
          }
        }
      end

      it "does not raise an error" do
        expect { date }.not_to raise_error
      end
    end

    context "with a structured date that has no values (as seen in bg704jr7687)" do
      let(:cocina) do
        {
          "structuredValue" => [
            {
              "type" => "start",
              "status" => "primary"
            },
            {
              "type" => "end"
            }
          ],
          "type" => "creation",
          "encoding" => {
            "code" => "w3cdtf"
          }
        }
      end

      it { is_expected.to be_a CocinaDisplay::Dates::DateRange }
    end
  end

  describe "#value" do
    let(:cocina) { {"value" => "2023"} }

    it "returns the cocina value" do
      expect(date.value).to eq("2023")
    end
  end

  describe "#type" do
    let(:cocina) { {"value" => "2023", "type" => "creation"} }

    it "returns the cocina type attribute" do
      expect(date.type).to eq("creation")
    end
  end

  describe "#qualifier" do
    let(:cocina) { {"value" => "2023", "qualifier" => "approximate"} }

    it "returns the cocina qualifier attribute" do
      expect(date.qualifier).to eq("approximate")
    end
  end

  describe "qualified?" do
    context "when the date is qualified" do
      let(:cocina) { {"value" => "2023", "qualifier" => "questionable"} }

      it "returns true" do
        expect(date.qualified?).to be true
      end
    end

    context "when the date is not qualified" do
      let(:cocina) { {"value" => "2023"} }

      it "returns false" do
        expect(date.qualified?).to be false
      end
    end
  end

  describe "#encoding" do
    let(:cocina) { {"value" => "2023-01-01", "encoding" => {"code" => "iso8601"}} }

    it "returns the cocina encoding attribute" do
      expect(date.encoding).to eq("iso8601")
    end
  end

  describe "#encoding?" do
    context "when encoding is present" do
      let(:cocina) { {"value" => "2023-01-01", "encoding" => {"code" => "iso8601"}} }

      it "returns true" do
        expect(date.encoding?).to be true
      end
    end

    context "when encoding is not present" do
      let(:cocina) { {"value" => "2023"} }

      it "returns false" do
        expect(date.encoding?).to be false
      end
    end
  end

  describe "#start?" do
    context "when the date is a start date" do
      let(:cocina) { {"value" => "2023-01-01", "type" => "start"} }
      it "returns true" do
        expect(date.start?).to be true
      end
    end
  end

  describe "#end?" do
    context "when the date is an end date" do
      let(:cocina) { {"value" => "2023-01-01", "type" => "end"} }
      it "returns true" do
        expect(date.end?).to be true
      end
    end
  end

  describe "#primary?" do
    context "when status is primary" do
      let(:cocina) { {"value" => "2023", "status" => "primary"} }

      it "returns true" do
        expect(date.primary?).to be true
      end
    end

    context "when status is not primary" do
      let(:cocina) { {"value" => "2023", "status" => "secondary"} }

      it "returns false" do
        expect(date.primary?).to be false
      end
    end
  end

  describe "#questionable?" do
    context "when qualifier is questionable" do
      let(:cocina) { {"value" => "2023", "qualifier" => "questionable"} }

      it "returns true" do
        expect(date.questionable?).to be true
      end
    end

    context "when qualifier is not questionable" do
      let(:cocina) { {"value" => "2023", "qualifier" => "approximate"} }

      it "returns false" do
        expect(date.questionable?).to be false
      end
    end
  end

  describe "#inferred?" do
    context "when qualifier is inferred" do
      let(:cocina) { {"value" => "2023", "qualifier" => "inferred"} }

      it "returns true" do
        expect(date.inferred?).to be true
      end
    end

    context "when qualifier is not inferred" do
      let(:cocina) { {"value" => "2023", "qualifier" => "approximate"} }

      it "returns false" do
        expect(date.inferred?).to be false
      end
    end
  end

  describe "#approximate?" do
    context "when qualifier is approximate" do
      let(:cocina) { {"value" => "2023", "qualifier" => "approximate"} }

      it "returns true" do
        expect(date.approximate?).to be true
      end
    end

    context "when qualifier is not approximate" do
      let(:cocina) { {"value" => "2023", "qualifier" => "inferred"} }

      it "returns false" do
        expect(date.approximate?).to be false
      end
    end
  end

  describe "#parsed_date?" do
    context "when the date is parsable" do
      let(:cocina) { {"value" => "2023"} }

      it "returns true" do
        expect(date.parsed_date?).to be true
      end
    end

    context "when the date is not parsable" do
      let(:cocina) { {"value" => "invalid-date"} }

      it "returns false" do
        expect(date.parsed_date?).to be false
      end
    end
  end

  describe "#precision" do
    context "with a century date" do
      let(:cocina) { {"value" => "19xx", "encoding" => {"code" => "edtf"}} }

      it "returns :century" do
        expect(date.precision).to eq(:century)
      end
    end

    context "with a decade" do
      let(:cocina) { {"value" => "196x", "encoding" => {"code" => "edtf"}} }

      it "returns :decade" do
        expect(date.precision).to eq(:decade)
      end
    end

    context "with a season" do
      # Spring 1960 in EDTF
      let(:cocina) { {"value" => "1960-21", "encoding" => {"code" => "edtf"}} }

      it "returns :month" do
        expect(date.precision).to eq(:month)
      end
    end

    context "with an interval" do
      # Day precision on start
      let(:cocina) { {"value" => "2004-02-01/2005", "encoding" => {"code" => "edtf"}} }

      it "returns the precision of the calculated interval" do
        expect(date.precision).to eq(:day)
      end
    end

    context "with a year" do
      let(:cocina) { {"value" => "2023", "encoding" => {"code" => "edtf"}} }

      it "returns :year" do
        expect(date.precision).to eq(:year)
      end
    end

    context "with a month" do
      let(:cocina) { {"value" => "2023-01", "encoding" => {"code" => "edtf"}} }

      it "returns :month" do
        expect(date.precision).to eq(:month)
      end
    end

    context "with an unparsable date" do
      let(:cocina) { {"value" => "invalid-date", "encoding" => {"code" => "edtf"}} }

      it "returns :unknown" do
        expect(date.precision).to eq(:unknown)
      end
    end
  end

  describe "#sort_key" do
    let(:date_values) do
      [
        "2023-01-01",
        "2023-01-02",
        "2023",
        "2022-10-30/2023-01-01",
        "966",
        "22",
        "19xx",
        "196x",
        "0",
        "-1",
        "-35"
      ]
    end
    let(:cocina_dates) { date_values.map { |v| {"value" => v, "encoding" => {"code" => "edtf"}} } }
    let(:dates) { cocina_dates.map { |c| described_class.from_cocina(c) } }

    it "sorts dates correctly" do
      sorted_dates = dates.sort
      expect(sorted_dates.map(&:value)).to eq([
        "-35",
        "-1",
        "0",
        "22",
        "966",
        "19xx",
        "196x",
        "2022-10-30/2023-01-01",
        "2023",
        "2023-01-01",
        "2023-01-02"
      ])
    end
  end

  describe "#to_a" do
    context "with a date range" do
      let(:cocina) { {"value" => "2023-01-01/2023-01-31", "encoding" => {"code" => "edtf"}} }

      it "returns the full range" do
        expect(date.to_a).to eq((Date.parse("2023-01-01")..Date.parse("2023-01-31")).to_a)
        expect(date.to_a.length).to eq(31)
      end
    end

    context "with an EDTF::Set" do
      let(:cocina) { {"value" => "[1991-01-01, 1992-02-01]", "encoding" => {"code" => "edtf"}} }

      it "returns only the dates in the set" do
        expect(date.to_a).to eq([Date.parse("1991-01-01"), Date.parse("1992-02-01")])
        expect(date.to_a.length).to eq(2)
      end
    end
  end

  describe "#decoded_value" do
    {
      "-23" => "24 BCE",
      "-1" => "2 BCE",
      "0" => "1 BCE",
      "1" => "1 CE",
      "433" => "433 CE"
    }.each do |value, expected|
      context "with value #{value}" do
        let(:cocina) { {"value" => value, "encoding" => {"code" => "edtf"}} }

        it "returns #{expected}" do
          expect(date.decoded_value).to eq(expected)
        end
      end
    end

    context "with a BCE century date" do
      let(:cocina) { {"value" => "-0099", "encoding" => {"code" => "edtf"}} }

      it "returns the century in BCE" do
        expect(date.decoded_value(allowed_precisions: [:century])).to eq("2nd century BCE")
      end
    end

    context "with date 2023-01-01" do
      let(:cocina) { {"value" => "2023-01-01", "encoding" => {"code" => "edtf"}} }

      [
        ["2023-01-01", [:day], "January  1, 2023"],
        ["2023-01-01", [:month], "January 2023"],
        ["2023-01-01", [:year], "2023"],
        ["2023-01-01", [:decade], "2020s"],
        ["2023-01-01", [:century], "21st century"]
      ].each do |value, allowed_precisions, expected|
        context "with allowed precisions #{allowed_precisions}" do
          it "returns #{expected}" do
            expect(date.decoded_value(allowed_precisions: allowed_precisions)).to eq(expected)
          end
        end
      end

      context "with several allowed precisions" do
        it "returns the most precise value" do
          expect(date.decoded_value(allowed_precisions: [:day, :month, :year])).to eq("January  1, 2023")
        end
      end
    end

    context "with a structuredValue that encodes an open ended range" do
      let(:cocina) do
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
      end

      it "returns the cocina value" do
        expect(date.decoded_value).to eq("1758 - Unknown")
      end
    end

    context "with an unparsable date" do
      let(:cocina) { {"value" => "invalid-date", "encoding" => {"code" => "edtf"}} }

      it "returns the value unmodified" do
        expect(date.decoded_value).to eq("invalid-date")
      end

      context "with ignore_unparseable true" do
        it "returns nil" do
          expect(date.decoded_value(ignore_unparseable: true)).to be_nil
        end
      end
    end

    context "with an unencoded date" do
      let(:cocina) { {"value" => "about 933"} }

      it "returns the value unmodified" do
        expect(date.decoded_value).to eq("about 933")
      end

      context "with display_original_value false" do
        it "returns the decoded value" do
          expect(date.decoded_value(display_original_value: false)).to eq("933 CE")
        end
      end
    end

    context "with an interval" do
      let(:cocina) { {"value" => "2023-01-01/2023-01-31", "encoding" => {"code" => "edtf"}} }

      it "returns the decoded value as a date range" do
        expect(date.decoded_value).to eq("January  1, 2023 - January 31, 2023")
      end
    end
  end

  describe "#qualified_value" do
    context "with date 2023-01" do
      let(:cocina) { {"value" => "2023-01", "qualifier" => qualifier, "encoding" => {"code" => "edtf"}} }

      [
        ["approximate", "[ca. January 2023]"],
        ["questionable", "[January 2023?]"],
        ["inferred", "[January 2023]"],
        [nil, "January 2023"]
      ].each do |qualifier_type, expected|
        context "when the qualifier is #{qualifier_type || "not present"}" do
          let(:qualifier) { qualifier_type }

          it "returns #{expected}" do
            expect(date.qualified_value).to eq(expected)
          end
        end
      end
    end
  end

  describe "ISO8601 encoded dates" do
    {
      "20131114161429" => Date.parse("20131114161429")..Date.parse("20131114161429")
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data, "encoding" => {"code" => "iso8601"}} }

        it "has the range value #{expected}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end

  describe "W3CDTF encoded dates" do
    {
      "2013-08-00" => Date.parse("2013-08-01")..Date.parse("2013-08-31")
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data, "encoding" => {"code" => "w3cdtf"}} }

        it "has the range value #{expected}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end

  describe "EDTF encoded dates" do
    {
      "1905" => Date.parse("1905-01-01")..Date.parse("1905-12-31"),
      "190u" => Date.parse("1900-01-01")..Date.parse("1909-12-31"),
      "190x" => Date.parse("1900-01-01")..Date.parse("1909-12-31"),
      "19uu" => Date.parse("1900-01-01")..Date.parse("1999-12-31"),
      "19xx" => Date.parse("1900-01-01")..Date.parse("1999-12-31"),
      "1856/1876" => Date.parse("1856-01-01")..Date.parse("1876-12-31"),
      "[1667,1668,1670..1672]" => Date.parse("1667-01-01")..Date.parse("1672-12-31"),
      "1900-uu" => Date.parse("1900-01-01")..Date.parse("1900-12-31"),
      "1900-uu-uu" => Date.parse("1900-01-01")..Date.parse("1900-12-31"),
      "1900-uu-15" => Date.parse("1900-01-15")..Date.parse("1900-12-15"),
      "1900-06-uu" => Date.parse("1900-06-01")..Date.parse("1900-06-30"),
      "-250" => Date.parse("-250-01-01")..Date.parse("-250-12-31"), # EDTF requires a 4 digit year, but what can you do.
      "63" => Date.parse("0063-01-01")..Date.parse("0063-12-31"),
      "125" => Date.parse("125-01-01")..Date.parse("125-12-31"),
      "1600-02" => "1600-02-01..1600-02-29"  # 1600 is a leap year; February has 29 days
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data, "encoding" => {"code" => "edtf"}} }

        it "has the range value #{expected}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end

  describe "MARC encoded dates" do
    {
      "1234" => Date.parse("1234-01-01")..Date.parse("1234-12-31"),
      "9999" => nil,
      "1uuu" => Date.parse("1000-01-01")..Date.parse("1999-12-31"),
      "||||" => nil
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data, "encoding" => {"code" => "marc"}} }

        it "has the range value #{expected || "nil"}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end

  describe "M/D/Y dates" do
    {
      "11/27/2017" => Date.parse("2017-11-27")..Date.parse("2017-11-27"),
      "5/27/2017" => Date.parse("2017-05-27")..Date.parse("2017-05-27"),
      "5/2/2017" => Date.parse("2017-05-02")..Date.parse("2017-05-02"),
      "12/1/2017" => Date.parse("2017-12-01")..Date.parse("2017-12-01"),
      "12/1/17" => Date.parse("2017-12-01")..Date.parse("2017-12-01"),
      "12/1/99" => Date.parse("1999-12-01")..Date.parse("1999-12-01"),
      "6/18/938" => Date.parse("0938-06-18")..Date.parse("0938-06-18")
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data} }

        it "has the range value #{expected}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end

  describe "Well-formed dates with no declared encoding" do
    {
      "2019-08-10" => Date.parse("2019-08-10")..Date.parse("2019-08-10"),
      "2019-08" => Date.parse("2019-08-01")..Date.parse("2019-08-31"),
      "2019" => Date.parse("2019-01-01")..Date.parse("2019-12-31")
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data} }

        it "has the range value #{expected}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end

  describe "Pulling out 4-digit years from unspecified dates" do
    {
      "Minguo 19 [1930]" => Date.parse("1930-01-01")..Date.parse("1930-12-31"),
      "1745 mag. 14" => Date.parse("1745-01-01")..Date.parse("1745-12-31"),
      "-745" => "", # too ambiguous to even attempt.
      "-1999" => "", # too ambiguous to even attempt.
      "[1923]" => Date.parse("1923-01-01")..Date.parse("1923-12-31"),
      "1532." => Date.parse("1532-01-01")..Date.parse("1532-12-31"),
      "[ca 1834]" => Date.parse("1834-01-01")..Date.parse("1834-12-31"),
      "xvi" => Date.parse("1500-01-01")..Date.parse("1599-12-31"),
      "cent. xvi" => Date.parse("1500-01-01")..Date.parse("1599-12-31"),
      "MDLXXVIII" => Date.parse("1578-01-01")..Date.parse("1578-12-31"),
      "[19--?]-" => Date.parse("1900-01-01")..Date.parse("1999-12-31"),
      "19th Century" => Date.parse("1800-01-01")..Date.parse("1899-12-31"),
      "19th c." => Date.parse("1800-01-01")..Date.parse("1899-12-31"),
      "mid to 2nd half of 13th century" => Date.parse("1200-01-01")..Date.parse("1299-12-31"),
      "167-?]" => Date.parse("1670-01-01")..Date.parse("1679-12-31"),
      "189-?" => Date.parse("1890-01-01")..Date.parse("1899-12-31"),
      "193-" => Date.parse("1930-01-01")..Date.parse("1939-12-31"),
      "196_" => Date.parse("1960-01-01")..Date.parse("1969-12-31"),
      "196x" => Date.parse("1960-01-01")..Date.parse("1969-12-31"),
      "196u" => Date.parse("1960-01-01")..Date.parse("1969-12-31"),
      "1960s" => Date.parse("1960-01-01")..Date.parse("1969-12-31"),
      "186?" => Date.parse("1860-01-01")..Date.parse("1869-12-31"),
      "1700?" => Date.parse("1700-01-01")..Date.parse("1700-12-31"),
      "early 1730s" => Date.parse("1730-01-01")..Date.parse("1739-12-31"),
      "[1670-1684]" => Date.parse("1670-01-01")..Date.parse("1684-12-31"),
      "[18]74" => Date.parse("1874-01-01")..Date.parse("1874-12-31"),
      "22" => Date.parse("0022-01-01")..Date.parse("0022-12-31"),
      "223" => Date.parse("0223-01-01")..Date.parse("0223-12-31"),
      "250 B.C." => Date.parse("-0249-01-01")..Date.parse("-249-12-31"),
      "Anno M.DC.LXXXI." => Date.parse("1681-01-01")..Date.parse("1681-12-31"),
      "624[1863 or 1864]" => Date.parse("1863-01-01")..Date.parse("1863-12-31"),
      "chez Villeneuve" => nil,
      "‏4264681 או 368" => nil
    }.each do |data, expected|
      describe "with #{data}" do
        let(:cocina) { {"value" => data} }

        it "has the range #{expected}" do
          expect(date.as_range.to_s).to eq expected.to_s
        end
      end
    end
  end
end

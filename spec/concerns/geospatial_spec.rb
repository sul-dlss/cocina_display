require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:subjects) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "subject" => subjects
      }
    }.to_json
  end
  let(:cocina_record) { described_class.from_json(cocina_json) }

  describe "#geonames_ids" do
    subject { cocina_record.geonames_ids }

    context "with no place subject" do
      it { is_expected.to be_empty }
    end

    context "with a non-place subject" do
      let(:subjects) do
        [
          {
            "type" => "topic",
            "value" => "Climate change"
          }
        ]
      end

      it { is_expected.to be_empty }
    end

    context "with a place subject without a geonames ID" do
      let(:subjects) do
        [
          {
            "type" => "place",
            "value" => "California"
          }
        ]
      end

      it { is_expected.to be_empty }
    end

    context "with a coverage subject with a geonames URI" do
      let(:subjects) do
        [
          {
            "value" => "Mexico",
            "type" => "coverage",
            "uri" => "http://sws.geonames.org/3996063/"
          }
        ]
      end

      it { is_expected.to contain_exactly("3996063") }
    end
  end

  describe "#coordinates" do
    subject { cocina_record.coordinates }

    context "with no subjects" do
      let(:subjects) { [] }

      it { is_expected.to be_empty }
    end

    context "with point coordinates" do
      let(:subjects) do
        [
          {
            "type" => "point coordinates",
            "structuredValue" => coordinates
          }
        ]
      end

      context "when empty" do
        let(:coordinates) { [] }

        it { is_expected.to be_empty }
      end

      context "when missing lat/long" do
        let(:coordinates) do
          [
            {"value" => "-121.24658", "type" => "longitude"}
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with non-numeric lat/long" do
        let(:coordinates) do
          [
            {"value" => "invalid", "type" => "latitude"},
            {"value" => "36.740468", "type" => "longitude"}
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with invalid lat/long" do
        let(:coordinates) do
          [
            {"value" => "226", "type" => "latitude"},
            {"value" => "26", "type" => "longitude"}
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with valid lat and long" do
        subject { cocina_record.coordinates.first }

        let(:coordinates) do
          [
            {"value" => "36.740468", "type" => "latitude"},
            {"value" => "-121.24658", "type" => "longitude"}
          ]
        end

        it "returns a point with latitude and longitude in DMS form" do
          is_expected.to eq("36°44′26″N 121°14′48″W")
        end
      end
    end

    context "with bounding box coordinates" do
      context "with no structuredValues" do
        let(:subjects) do
          [
            {
              "type" => "bounding box coordinates"
            }
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with missing structuredValues" do
        let(:subjects) do
          [
            {
              "type" => "bounding box coordinates",
              "structuredValue" => [
                {"value" => "36.740468", "type" => "south"},
                {"value" => "-121.24658", "type" => "west"},
                {"value" => "36.750468", "type" => "north"}
              ]
            }
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with invalid data" do
        let(:subjects) do
          [
            {
              "type" => "bounding box coordinates",
              "structuredValue" => [
                {"value" => "invalid", "type" => "south"},
                {"value" => "-121.24658", "type" => "west"},
                {"value" => "36.750468", "type" => "north"},
                {"value" => "-121.23658", "type" => "east"}
              ]
            }
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with out-of-bounds data" do
        let(:subjects) do
          [
            {
              "type" => "bounding box coordinates",
              "structuredValue" => [
                {"value" => "999", "type" => "south"},
                {"value" => "-121.24658", "type" => "west"},
                {"value" => "36.750468", "type" => "north"},
                {"value" => "-121.23658", "type" => "east"}
              ]
            }
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with data where points are reversed" do
        let(:subjects) do
          [
            {
              "type" => "bounding box coordinates",
              "structuredValue" => [
                {"value" => "36.740468", "type" => "north"},
                {"value" => "-121.24658", "type" => "east"},
                {"value" => "37.633575", "type" => "south"},
                {"value" => "-120.051476", "type" => "west"}
              ]
            }
          ]
        end

        it { is_expected.to be_empty }
      end

      context "with complete and valid data" do
        subject { cocina_record.coordinates.first }

        let(:subjects) do
          [
            {
              "type" => "bounding box coordinates",
              "structuredValue" => [
                {"value" => "-121.24658", "type" => "west"},
                {"value" => "36.740468", "type" => "south"},
                {"value" => "-120.051476", "type" => "east"},
                {"value" => "37.633575", "type" => "north"}
              ]
            }
          ]
        end

        it "returns the bounding box in DMS form" do
          is_expected.to eq("121°14′48″W -- 120°03′05″W / 37°38′01″N -- 36°44′26″N")
        end
      end
    end

    context "with map coordinates" do
      subject { cocina_record.coordinates.first }

      let(:subjects) do
        [
          {
            "type" => "map coordinates",
            "value" => coordinates
          }
        ]
      end

      context "with simple valid DMS" do
        # druid:jf265tf7947
        let(:coordinates) { "W 18°--E 51°/N 37°--S 35°" }

        it "parses and formats correctly" do
          is_expected.to eq("18°00′00″W -- 51°00′00″E / 37°00′00″N -- 35°00′00″S")
        end
      end

      context "with full valid DMS" do
        let(:coordinates) { "W 125°13′13″--W 062°04′30″/N 049°28′22″--N 024°26′06″" }

        it "parses and formats correctly" do
          is_expected.to eq("125°13′13″W -- 62°04′30″W / 49°28′22″N -- 24°26′06″N")
        end
      end

      context "with alternate quote characters" do
        let(:coordinates) { "W 42°00'00\"--E 72°30'00\"/N 46°00'00\"--S 50°30'00\")." }

        it "parses and formats correctly" do
          is_expected.to eq("42°00′00″W -- 72°30′00″E / 46°00′00″N -- 50°30′00″S")
        end
      end

      context "with random whitespace and punctuation" do
        # druid:wb607wf5736
        let(:coordinates) { "E 7°30′--E 50°25′/N 5°--S\n            35°'" }

        it "parses and formats correctly" do
          is_expected.to eq("7°30′00″E -- 50°25′00″E / 5°00′00″N -- 35°00′00″S")
        end
      end

      context "with alternate degree symbols and trailing punctuation" do
        let(:coordinates) { "W 170⁰--E 55⁰/N 40⁰--S 36⁰)." }

        it "parses and formats correctly" do
          is_expected.to eq("170°00′00″W -- 55°00′00″E / 40°00′00″N -- 36°00′00″S")
        end
      end

      context "with out-of-bounds coordinates" do
        # druid:wb361fc1542
        let(:coordinates) { "W 008°00′00″--W 004°00′00″/N 059°00′00″--N 543°00′00″" }

        it "returns the original string" do
          is_expected.to eq("W 008°00′00″--W 004°00′00″/N 059°00′00″--N 543°00′00″")
        end
      end

      context "with decimal degrees with hemispheres" do
        # druid:nx837tk2752
        let(:coordinates) { "W 024.93--E 011.87/N 066.64--N 042.71" }

        it "parses and formats correctly" do
          is_expected.to eq("24°55′48″W -- 11°52′12″E / 66°38′24″N -- 42°42′36″N")
        end
      end

      context "with decimal degrees and leading text" do
        # druid:wb091yf8384
        let(:coordinates) { "In decimal degrees: (W 126.04--W 052.03/N 050.37--N 006.87)." }

        it "parses and formats correctly" do
          is_expected.to eq("126°02′24″W -- 52°01′48″W / 50°22′12″N -- 6°52′12″N")
        end
      end

      context "with decimal degrees and scale statement from MARC" do
        # druid:vd002bm9939
        let(:coordinates) { "$b3100000W 120°00′00″--W 114°00′00″/N 042°00′00″--N 036°00′00″" }

        it "parses and formats correctly" do
          is_expected.to eq("120°00′00″W -- 114°00′00″W / 42°00′00″N -- 36°00′00″N")
        end
      end

      context "with MARC DMS format" do
        # druid:wr293dm6322
        let(:coordinates) { "$dW0963700$eW0900700$fN0433000$gN040220" }

        it "parses and formats correctly" do
          is_expected.to eq("96°37′00″W -- 90°07′00″W / 43°30′00″N -- 40°22′00″N")
        end
      end

      context "with MARC decimal format" do
        # druid:kb680jd5142
        let(:coordinates) { "$d-112.0785250$e-111.6012719$f037.6516503$g036.8583209" }

        it "parses and formats correctly with rounding" do
          is_expected.to eq("112°04′43″W -- 111°36′05″W / 37°39′06″N -- 36°51′30″N")
        end
      end

      # Arguably bad data, but it is possible to parse correctly as-is.
      context "with DMS coordinates and scale from MARC 034" do
        # druid:vd002bm9939
        let(:coordinates) { "$b3100000W 120°00′00″--W 114°00′00″/N 042°00′00″--N 036°00′00″" }

        it "parses and formats correctly" do
          is_expected.to eq("120°00′00″W -- 114°00′00″W / 42°00′00″N -- 36°00′00″N")
        end
      end

      # NOTE: this is a pathological case where the $b scale info got turned into
      # a fake DMS coordinate and the real coordinate is left at the end.
      # There are potentially hundreds of these, but we're going to remediate them
      # instead of attempting to be smart about the parsing.
      context "with a poorly parsed MARC 034" do
        # druid:sw279br4627
        let(:coordinates) { "b 164°18′36″--W 047°40′00″/W 031°40′00″--N 066°00′00″$gN0590800" }

        it "returns the original string" do
          is_expected.to eq("b 164°18′36″--W 047°40′00″/W 031°40′00″--N 066°00′00″$gN0590800")
        end
      end

      context "with a single point in decimal degrees" do
        # druid:sb789ym1480
        let(:coordinates) { "41.891797, 12.486419" }

        it "parses and formats correctly" do
          is_expected.to eq("41°53′30″N 12°29′11″E")
        end
      end

      context "with a single point in DMS" do
        let(:coordinates) { "N 41°53′30″ E 12°29′11″" }

        it "parses and reformats correctly" do
          is_expected.to eq("41°53′30″N 12°29′11″E")
        end
      end
    end

    context "with multiple coordinate subjects" do
      let(:subjects) do
        [
          {
            "type" => "point coordinates",
            "structuredValue" => [
              {"value" => "36.740468", "type" => "latitude"},
              {"value" => "-121.24658", "type" => "longitude"}
            ]
          },
          {
            "type" => "map coordinates",
            "value" => "N 36°44′26″ W 121°14′48″"
          }
        ]
      end

      it "deduplicates after converting to DMS" do
        is_expected.to contain_exactly("36°44′26″N 121°14′48″W")
      end
    end
  end

  describe "#coordinates_as_wkt" do
    context "with a point and a bounding box" do
      let(:subjects) do
        [
          {
            "type" => "point coordinates",
            "structuredValue" => [
              {"value" => "36.740468", "type" => "latitude"},
              {"value" => "-121.24658", "type" => "longitude"}
            ]
          },
          {
            "type" => "bounding box coordinates",
            "structuredValue" => [
              {"value" => "-121.24658", "type" => "west"},
              {"value" => "36.740468", "type" => "south"},
              {"value" => "-120.051476", "type" => "east"},
              {"value" => "37.633575", "type" => "north"}
            ]
          }
        ]
      end

      subject { cocina_record.coordinates_as_wkt }

      it "returns the point in WKT format" do
        expect(subject[0]).to eq("POINT(36.740468 -121.246580)")
      end

      it "returns the box in WKT format" do
        expect(subject[1]).to eq("POLYGON((-121.246580 36.740468, -120.051476 36.740468, -120.051476 37.633575, -121.246580 37.633575, -121.246580 36.740468))")
      end
    end
  end

  describe "#coordinates_as_envelope" do
    context "with a point and a bounding box" do
      let(:subjects) do
        [
          {
            "type" => "point coordinates",
            "structuredValue" => [
              {"value" => "36.740468", "type" => "latitude"},
              {"value" => "-121.24658", "type" => "longitude"}
            ]
          },
          {
            "type" => "bounding box coordinates",
            "structuredValue" => [
              {"value" => "-121.24658", "type" => "west"},
              {"value" => "36.740468", "type" => "south"},
              {"value" => "-120.051476", "type" => "east"},
              {"value" => "37.633575", "type" => "north"}
            ]
          }
        ]
      end

      subject { cocina_record.coordinates_as_envelope.first }

      it "returns only the box in Solr envelope format (not the point)" do
        is_expected.to eq("ENVELOPE(-121.246580, -120.051476, 37.633575, 36.740468)")
      end
    end
  end

  describe "#coordinates_as_point" do
    context "with a point and a bounding box" do
      let(:subjects) do
        [
          {
            "type" => "point coordinates",
            "structuredValue" => [
              {"value" => "36.740468", "type" => "latitude"},
              {"value" => "-121.24658", "type" => "longitude"}
            ]
          },
          {
            "type" => "bounding box coordinates",
            "structuredValue" => [
              {"value" => "-121.24658", "type" => "west"},
              {"value" => "36.740468", "type" => "south"},
              {"value" => "-120.051476", "type" => "east"},
              {"value" => "37.633575", "type" => "north"}
            ]
          }
        ]
      end

      subject { cocina_record.coordinates_as_point }

      it "returns the point in Solr LatLon format" do
        expect(subject[0]).to eq("36.740468,-121.246580")
      end

      it "returns the box center in Solr LatLon format" do
        expect(subject[1]).to eq("37.188545,-120.652546")
      end
    end
  end
end

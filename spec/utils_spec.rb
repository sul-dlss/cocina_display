require "spec_helper"

RSpec.describe CocinaDisplay::Utils do
  describe "#flatten_nested_values" do
    subject { described_class.flatten_nested_values(cocina) }

    context "with deeply nested structured values" do
      let(:cocina) do
        {
          "structuredValue" => [
            "structuredValue" => [
              "structuredValue" => [
                {"value" => "John Doe", "type" => "name"},
                {"value" => "1920 - 2000", "type" => "life dates"},
                {"value" => "Foo", "type" => "foo"}
              ]
            ]
          ]
        }
      end

      it "flattens all levels" do
        is_expected.to eq([
          {"value" => "John Doe", "type" => "name"},
          {"value" => "1920 - 2000", "type" => "life dates"},
          {"value" => "Foo", "type" => "foo"}
        ])
      end
    end

    context "with no nesting" do
      let(:cocina) do
        {
          "value" => "John Doe",
          "type" => "name"
        }
      end

      it "returns the single node" do
        is_expected.to eq([cocina])
      end
    end

    context "with grouped values" do
      let(:cocina) do
        # from druid:sw705fr7011
        {"groupedValue" =>
          [{"value" => "audiotape reel",
            "type" => "form",
            "uri" => "http://id.loc.gov/vocabulary/carriers/st",
            "source" =>
             {"code" => "rdacarrier", "uri" => "http://id.loc.gov/vocabulary/carriers"}},
            {"value" => "access",
             "type" => "reformatting quality",
             "source" => {"value" => "MODS reformatting quality terms"}},
            {"value" => "audio/mpeg",
             "type" => "media type",
             "source" => {"value" => "IANA media types"}},
            {"value" => "1 audiotape", "type" => "extent"},
            {"value" => "reformatted digital",
             "type" => "digital origin",
             "source" => {"value" => "MODS digital origin terms"}}]}
      end

      it "flattens grouped values into a single array" do
        is_expected.to eq([
          {"value" => "audiotape reel", "type" => "form", "uri" => "http://id.loc.gov/vocabulary/carriers/st", "source" => {"code" => "rdacarrier", "uri" => "http://id.loc.gov/vocabulary/carriers"}},
          {"value" => "access", "type" => "reformatting quality", "source" => {"value" => "MODS reformatting quality terms"}},
          {"value" => "audio/mpeg", "type" => "media type", "source" => {"value" => "IANA media types"}},
          {"value" => "1 audiotape", "type" => "extent"},
          {"value" => "reformatted digital", "type" => "digital origin", "source" => {"value" => "MODS digital origin terms"}}
        ])
      end
    end
  end

  describe "#deep_compact_blank" do
    subject { described_class.deep_compact_blank(hash) }

    context "with nested empty values" do
      let(:hash) do
        {
          "name" => "John Doe",
          "age" => nil,
          "address" => {
            "street" => "123 Main St",
            "city" => "",
            "state" => "CA"
          },
          "empty_array" => [],
          "empty_hash" => {},
          "nested_empty" => {
            "key" => nil,
            "another_empty" => []
          }
        }
      end

      it "removes keys with empty values" do
        is_expected.to eq({
          "name" => "John Doe",
          "address" => {
            "street" => "123 Main St",
            "state" => "CA"
          }
        })
      end
    end

    context "with arrays containing empty values" do
      let(:hash) do
        {
          "tags" => ["tag1", "", nil, "tag2"],
          "comments" => [
            {"author" => "Alice", "text" => "Great post!"},
            {"author" => "", "text" => ""},
            {"author" => "Bob", "text" => nil}
          ]
        }
      end

      it "removes empty values from arrays" do
        is_expected.to eq({
          "tags" => ["tag1", "tag2"],
          "comments" => [
            {"author" => "Alice", "text" => "Great post!"},
            {"author" => "Bob"}
          ]
        })
      end
    end

    context "with no empty values" do
      let(:hash) do
        {
          "name" => "John Doe",
          "age" => 30,
          "address" => {
            "street" => "123 Main St",
            "city" => "Anytown",
            "state" => "CA"
          }
        }
      end

      it "returns the original hash" do
        is_expected.to eq(hash)
      end
    end

    context "with false" do
      let(:hash) do
        {
          "name" => "John Doe",
          "isMinor" => false
        }
      end

      it "returns the original hash" do
        is_expected.to eq(hash)
      end
    end
  end

  describe "#compact_and_join" do
    subject { described_class.compact_and_join(values, delimiter: delimiter) }

    let(:delimiter) { ", " }

    context "with blank and nil values" do
      let(:values) { ["Alice", "", nil, "Bob", "  ", "Charlie"] }

      it "removes blank and nil values and joins the rest" do
        is_expected.to eq("Alice, Bob, Charlie")
      end
    end

    context "with all values blank or nil" do
      let(:values) { ["", "   ", nil] }

      it "returns an empty string" do
        is_expected.to eq("")
      end
    end

    context "with a single non-blank value" do
      let(:values) { [nil, "  ", "Alice", "   "] }

      it "returns the single value without delimiters" do
        is_expected.to eq("Alice")
      end
    end

    context "with custom delimiter" do
      let(:values) { ["Apple", "Banana", "Cherry"] }
      let(:delimiter) { " | " }

      it "joins values using the custom delimiter" do
        is_expected.to eq("Apple | Banana | Cherry")
      end
    end

    context "when values start or end with the delimiter" do
      # from druid:bm971cx9348
      let(:delimiter) { " -- " }
      let(:values) { ["-- pt.2. Abergavenny", "-- pt.5. Merthyr Tydfil"] }

      it "does not duplicate delimiter" do
        is_expected.to eq("-- pt.2. Abergavenny -- pt.5. Merthyr Tydfil")
      end
    end
  end
end

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

    context "with parallel values" do
      let(:cocina) do
        {
          "parallelValue" => [
            {"value" => "John Doe", "type" => "name"},
            {"value" => "Jane Smith", "type" => "name"}
          ]
        }
      end

      it "flattens parallel values into a single array" do
        is_expected.to eq([
          {"value" => "John Doe", "type" => "name"},
          {"value" => "Jane Smith", "type" => "name"}
        ])
      end
    end

    context "with mixed structured and parallel values" do
      let(:cocina) do
        {
          "parallelValue" => [
            {
              "value" => "John Doe",
              "type" => "name"
            },
            {
              "structuredValue" => [
                {"value" => "King", "type" => "term of address"},
                {"value" => "1920 - 2000", "type" => "life dates"}
              ]
            }
          ]
        }
      end

      it "flattens all nodes into a single array" do
        is_expected.to eq([
          {"value" => "John Doe", "type" => "name"},
          {"value" => "King", "type" => "term of address"},
          {"value" => "1920 - 2000", "type" => "life dates"}
        ])
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
  end

  describe "#display_data_from_objects" do
    subject { described_class.display_data_from_objects(objects) }

    let(:objects) do
      [
        {"value" => "English"},
        {"value" => "Spanish"},
        {"value" => ""},
        {"code" => "eng", "source" => {"code" => "iso639-2"}},
        {"value" => "English"},
        {"code" => "zxx"},
        {"code" => "egy-Egyd"},
        {"value" => "Sumerian", "displayLabel" => "Primary language"}
      ].map { |lang| CocinaDisplay::Language.new(lang) }
    end

    it "groups objects by label and keeps unique, non-blank values" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Language", values: ["English", "Spanish", "Egyptian, Demotic"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Primary language", values: ["Sumerian"]))
      )
    end
  end

  describe "#display_data_from_cocina" do
    subject { described_class.display_data_from_cocina(cocina, label: "Language") }

    let(:cocina) do
      [
        {"value" => "English"},
        {"value" => "Spanish"},
        {"value" => ""},
        {"value" => "English"},
        {"value" => "Sumerian", "displayLabel" => "Primary language"}
      ]
    end

    it "groups objects by label and keeps unique, non-blank values" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Language", values: ["English", "Spanish"])),
        be_a(CocinaDisplay::DisplayData).and(have_attributes(label: "Primary language", values: ["Sumerian"]))
      )
    end
  end
end

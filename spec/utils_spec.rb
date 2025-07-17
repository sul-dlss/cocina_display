require "spec_helper"

require_relative "../lib/cocina_display/utils"

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
end

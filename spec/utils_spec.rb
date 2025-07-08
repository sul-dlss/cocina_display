require "spec_helper"

require_relative "../lib/cocina_display/utils"

RSpec.describe CocinaDisplay::Utils do
  describe "#flatten_structured_values" do
    subject { described_class.flatten_structured_values(cocina) }

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
  end
end

require "spec_helper"

RSpec.describe CocinaDisplay::DisplayData do
  describe "#from_cocina" do
    let(:cocina) do
      {
        "value" => "my value"
      }
    end

    subject { CocinaDisplay::DisplayData.from_cocina(cocina) }

    it "stores the values" do
      expect(subject.values).to contain_exactly("my value")
    end

    it "has no label by default" do
      expect(subject.label).to be_nil
    end

    context "when a displayLabel is set" do
      let(:cocina) do
        {
          "value" => "my value",
          "displayLabel" => "My Label"
        }
      end

      it "stores the label" do
        expect(subject.label).to eq("My Label")
      end
    end
  end
end

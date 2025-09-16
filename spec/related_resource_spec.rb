# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::RelatedResource do
  let(:instance) { described_class.new(cocina_doc) }

  describe "titles" do
    subject { instance.main_title }

    context "when there is no title" do
      let(:cocina_doc) { {} }

      it { is_expected.to be_nil }
    end

    context "when there is a title" do
      let(:cocina_doc) do
        {
          "title" => [{"value" => "the title"}]
        }
      end

      it { is_expected.to eq "the title" }
    end
  end

  describe "#url" do
    subject { instance.url }

    let(:cocina_doc) do
      {
        "access" => {
          "url" => [
            {
              "value" => "http://www.oac.cdlib.org/findaid/ark:/13030/kt5b69s0t3"
            }
          ]
        }
      }
    end

    it { is_expected.to eq "http://www.oac.cdlib.org/findaid/ark:/13030/kt5b69s0t3" }
  end

  describe "#purl (as seen in rp193xx6845)" do
    subject { instance.purl }

    let(:cocina_doc) do
      {
        "purl" =>	"https://purl.stanford.edu/dz777fh8531"
      }
    end

    it { is_expected.to eq "https://purl.stanford.edu/dz777fh8531" }
  end
end

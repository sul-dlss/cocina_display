# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::RelatedResource do
  describe "titles" do
    subject { described_class.new(cocina_doc).main_title }

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

  describe "access" do
    [:purl_url, :oembed_url, :download_url, :iiif_manifest_url].each do |method|
      subject { described_class.new(cocina_doc).send(method) }

      describe "##{method}" do
        context "when there is no purl url" do
          let(:cocina_doc) do
            {
              "title" => [{"value" => "the title"}]
            }
          end

          it { is_expected.to be_nil }
        end
      end
    end

    context "when there is a purl url" do
      let(:cocina_doc) do
        {
          "title" => [{"value" => "the title"}],
          "purl" => "https://purl.stanford.edu/xx111yy2223"
        }
      end

      describe "#purl_url" do
        subject { described_class.new(cocina_doc).purl_url }

        it { is_expected.to eq "https://purl.stanford.edu/xx111yy2223" }
      end

      describe "#oembed_url" do
        subject { described_class.new(cocina_doc).oembed_url }

        it { is_expected.to eq "https://purl.stanford.edu/embed.json?url=https%3A%2F%2Fpurl.stanford.edu%2Fxx111yy2223" }
      end

      describe "#download_url" do
        subject { described_class.new(cocina_doc).download_url }

        it { is_expected.to eq "https://stacks.stanford.edu/object/xx111yy2223" }
      end

      describe "#iiif_manifest_url" do
        subject { described_class.new(cocina_doc).iiif_manifest_url }

        it { is_expected.to eq "https://purl.stanford.edu/xx111yy2223/iiif3/manifest" }
      end
    end
  end
end

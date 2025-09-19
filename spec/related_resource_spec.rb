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

  describe "link construction" do
    subject(:related_resource) { described_class.new(cocina_doc) }

    let(:link_data) do
      {title: related_resource.to_s, url: related_resource.url}
    end

    context "with a finding aid access link with title" do
      # from druid:gx074xz5520
      let(:cocina_doc) do
        {
          "title" => [{"value" => "Finding aid"}],
          "access" => {
            "url" => [
              {
                "value" => "http://www.oac.cdlib.org/findaid/ark:/13030/kt1h4nf2fr/"
              }
            ]
          }
        }
      end

      it { is_expected.to be_url }

      it "returns the correct title and url" do
        expect(link_data).to eq({title: "Finding aid", url: "http://www.oac.cdlib.org/findaid/ark:/13030/kt1h4nf2fr/"})
      end
    end

    context "with a purl link with no title" do
      # from druid:rp193xx6845
      let(:cocina_doc) do
        {
          "purl" => "https://purl.stanford.edu/rp193xx6845"
        }
      end

      it { is_expected.to be_url }

      it "uses the url as the link title" do
        expect(link_data).to eq({title: "https://purl.stanford.edu/rp193xx6845", url: "https://purl.stanford.edu/rp193xx6845"})
      end
    end
  end

  describe "#display_data" do
    subject { described_class.new(cocina_doc).display_data.map { |dd| {dd.label => dd.values} } }

    context "with title, contributor, and notes using display labels" do
      # taken from druid:hp566jq8781
      let(:cocina_doc) do
        {
          "type" => "has part",
          "title" => [
            {
              "structuredValue" => [
                {"value" => "Ranulf Higden OSB, Polychronicon (epitome and continuation to 1429)", "type" => "main title"},
                {"value" => "1r-29v", "type" => "part number"}
              ]
            },
            {
              "structuredValue" => [
                {"value" => "Epitome chronicae Cicestrensis, sed extractum e Polychronico, usque ad annum Christi 1429", "type" => "main title"},
                {"value" => "1r-29v", "type" => "part number"}
              ],
              "type" => "alternative",
              "displayLabel" => "Nasmith"
            }
          ],
          "contributor" => [
            {
              "name" => [{"value" => "Ranulf Higden OSB"}],
              "type" => "person",
              "role" => [{"value" => "author", "uri" => "http://id.loc.gov/vocabulary/relators/aut", "source" => {"code" => "marcrelator"}}]
            }
          ],
          "note" => [
            {"value" => "(1r) Ieronimus ad eugenium in epistola 43a dicit quod decime leguntur primum date ab abraham", "type" => "incipit", "displayLabel" => "Incipit"},
            {"value" => "Dates are marked in the margin"},
            {"value" => "Ends with the coronation of Henry VI at St Denis"},
            {"value" => "(29v) videlicet nono die mensis decembris ano etatis sue 10o", "type" => "explicit", "displayLabel" => "Explicit"}
          ]
        }
      end

      it "combines all display data" do
        is_expected.to eq([
          {"Title" => ["Ranulf Higden OSB, Polychronicon (epitome and continuation to 1429). 1r-29v"]},
          {"Nasmith" => ["Epitome chronicae Cicestrensis, sed extractum e Polychronico, usque ad annum Christi 1429. 1r-29v"]},
          {"Author" => ["Ranulf Higden OSB"]},
          {"Incipit" => ["(1r) Ieronimus ad eugenium in epistola 43a dicit quod decime leguntur primum date ab abraham"]},
          {"Note" => ["Dates are marked in the margin", "Ends with the coronation of Henry VI at St Denis"]},
          {"Explicit" => ["(29v) videlicet nono die mensis decembris ano etatis sue 10o"]}
        ])
      end
    end
  end
end

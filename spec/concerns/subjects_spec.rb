require "spec_helper"
require_relative "../../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:subjects) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "subject" => subjects
      }
    }.to_json
  end
  let(:record) { described_class.from_json(cocina_json) }

  describe "#subject_topics" do
    subject { record.subject_topics }

    context "with non-structured topic subjects" do
      let(:subjects) do
        [
          {"type" => "topic", "value" => "Climate change"}
        ]
      end

      it "returns the value as a string" do
        is_expected.to eq(["Climate change"])
      end
    end

    context "with structured topic subjects" do
      let(:subjects) do
        [
          {
            "type" => "topic",
            "structuredValue" => [
              {"value" => "Painters"},
              {"value" => "Italy"}
            ]
          }
        ]
      end

      it "joins the values with a delimiter" do
        is_expected.to eq(["Painters, Italy"])
      end
    end

    context "with structured topic subjects where type is only on structuredValue" do
      let(:subjects) do
        [
          {
            "structuredValue" => [
              {"value" => "Painters", "type" => "topic"},
              {"value" => "Italy", "type" => "topic"}
            ]
          }
        ]
      end

      it "joins the values with a delimiter" do
        is_expected.to eq(["Painters, Italy"])
      end
    end

    context "with catalog heading structured subjects" do
      let(:subjects) do
        [
          {
            "type" => "topic",
            "displayLabel" => "Catalog heading",
            "structuredValue" => [
              {"value" => "Painters"},
              {"value" => "Italy"}
            ]
          }
        ]
      end

      it "joins the values with >" do
        is_expected.to eq(["Painters > Italy"])
      end
    end

    context "with structured and unstructured duplicate subjects" do
      let(:subjects) do
        [
          {"type" => "topic", "value" => "Painters, Italy"},
          {
            "type" => "topic",
            "structuredValue" => [
              {"value" => "Painters"},
              {"value" => "Italy"}
            ]
          }
        ]
      end

      it "returns unique values" do
        is_expected.to eq(["Painters, Italy"])
      end
    end
  end

  describe "#subject_names" do
    subject { record.subject_names }

    context "with non-structured named subjects" do
      let(:subjects) do
        [
          {"type" => "person", "value" => "John Doe"}
        ]
      end

      it "returns the value as a string" do
        is_expected.to eq(["John Doe"])
      end
    end

    context "with structured named subjects" do
      let(:subjects) do
        [
          {
            "type" => "person",
            "structuredValue" => [
              {"value" => "Tiberius", "type" => "surname"},
              {"value" => "Claudius Nero", "type" => "forename"},
              {"value" => "Emperor of Rome", "type" => "term of address"},
              {"value" => "42 BC - 37 AD", "type" => "life dates"}
            ]
          }
        ]
      end

      it "joins the values with a delimiter" do
        is_expected.to eq(["Tiberius, Claudius Nero, Emperor of Rome, 42 BC - 37 AD"])
      end
    end

    context "with structured named subjects with parallel value" do
      let(:subjects) do
        [
          {
            "type" => "person",
            "parallelValue" => [
              {
                "structuredValue" => [
                  {"value" => "Tiberius", "type" => "surname"},
                  {"value" => "Claudius Nero", "type" => "forename"},
                  {"value" => "Emperor of Rome", "type" => "term of address"},
                  {"value" => "42 BC - 37 AD", "type" => "life dates"}
                ]
              },
              {
                "value" => "Tiberius, Claudius Nero, Emperor of Rome, 42 BC - 37 AD",
                "type" => "display"
              }
            ]
          }
        ]
      end

      it "does not duplicate formatted values" do
        is_expected.to eq(["Tiberius, Claudius Nero, Emperor of Rome, 42 BC - 37 AD"])
      end
    end
  end

  describe "#subject_titles" do
    subject { record.subject_titles }

    context "with non-structured title subjects" do
      let(:subjects) do
        [
          {"type" => "title", "value" => "The Great Gatsby"}
        ]
      end

      it "returns the value as a string" do
        is_expected.to eq(["The Great Gatsby"])
      end
    end

    context "with structured title subjects" do
      let(:subjects) do
        [
          {
            "type" => "title",
            "structuredValue" => [
              {
                "value" => "The",
                "type" => "nonsorting characters"
              },
              {
                "value" => "master and Margarita",
                "type" => "main title"
              }
            ]
          }
        ]
      end

      it "formats the title" do
        is_expected.to eq(["The master and Margarita"])
      end
    end
  end

  describe "#subject_genres" do
    subject { record.subject_genres }

    let(:subjects) do
      [
        {"type" => "genre", "value" => "Fiction"},
        {"type" => "genre", "value" => "Science Fiction"},
        {"type" => "topic", "value" => "History"}
      ]
    end

    it "returns the genre subject values" do
      is_expected.to eq(["Fiction", "Science Fiction"])
    end
  end

  describe "#subject_temporal" do
    subject { record.subject_temporal }

    context "with non-structured temporal subjects" do
      let(:subjects) do
        [
          {"type" => "time", "value" => "2020"}
        ]
      end

      it "returns the value as a string" do
        is_expected.to eq(["2020"])
      end
    end

    context "with structured temporal subjects" do
      let(:subjects) do
        [
          {
            "type" => "time",
            "structuredValue" => [
              {"value" => "1978", "type" => "start"},
              {"value" => "2005", "type" => "end"}
            ],
            "encoding" => {"code" => "w3cdtf"}
          }
        ]
      end

      it "formats the date values" do
        is_expected.to eq(["1978 - 2005"])
      end
    end
  end

  describe "#subject_occupations" do
    subject { record.subject_occupations }

    context "with non-structured occupation subjects" do
      let(:subjects) do
        [
          {"type" => "occupation", "value" => "Software Engineer"}
        ]
      end

      it "returns the value as a string" do
        is_expected.to eq(["Software Engineer"])
      end
    end

    context "with structured occupation subjects" do
      let(:subjects) do
        [
          {
            "type" => "occupation",
            "structuredValue" => [
              {"value" => "Artist"},
              {"value" => "Painter"}
            ]
          }
        ]
      end

      it "joins the values with a delimiter" do
        is_expected.to eq(["Artist, Painter"])
      end
    end
  end

  describe "faceting methods" do
    let(:subjects) do
      [
        {"type" => "topic", "value" => "Climate change"},
        {"type" => "occupation", "value" => "Software Engineer"},
        {"type" => "title", "value" => "The Great Gatsby"},
        {"type" => "genre", "value" => "Fiction"},
        {"type" => "time", "value" => "2020"},
        {"type" => "name", "value" => "John Doe"}
      ]
    end
    describe "#subject_all" do
      subject { record.subject_all }

      it "combines all subject facets" do
        is_expected.to eq(["Climate change", "Software Engineer", "John Doe", "The Great Gatsby", "2020", "Fiction"])
      end
    end

    describe "#subject_topics_other" do
      subject { record.subject_topics_other }

      it "returns topic, occupation, name, and title facets" do
        is_expected.to eq(["Climate change", "Software Engineer", "John Doe", "The Great Gatsby"])
      end
    end

    describe "#subject_other" do
      subject { record.subject_other }

      it "returns occupation, name, and title facets" do
        is_expected.to eq(["Software Engineer", "John Doe", "The Great Gatsby"])
      end
    end

    describe "#subject_temporal_genre" do
      subject { record.subject_temporal_genre }

      it "returns temporal and genre facets" do
        is_expected.to eq(["2020", "Fiction"])
      end
    end
  end
end

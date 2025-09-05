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

      it "returns the individual values" do
        is_expected.to eq(["Painters", "Italy"])
      end
    end

    context "with structured and unstructured duplicate subjects" do
      let(:subjects) do
        [
          {"type" => "topic", "value" => "Painters"},
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
        is_expected.to eq(["Painters", "Italy"])
      end
    end

    context "with a topic subject nested inside another subject" do
      # from druid:kj040zn0537
      let(:subjects) do
        [
          {
            "structuredValue" => [
              {
                "type" => "person",
                "structuredValue" => [
                  {"value" => "duchess d'", "type" => "term of address"},
                  {"value" => "Angoulême, Marie-Thérèse Charlotte de France", "type" => "name"},
                  {"value" => "1778-1851", "type" => "life dates"}
                ]
              },
              {
                "value" => "Emprisonnement",
                "type" => "topic"
              }
            ]
          }
        ]
      end

      it "extracts the topic value" do
        is_expected.to eq(["Emprisonnement"])
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

      it "returns the values separately" do
        is_expected.to eq(["Artist", "Painter"])
      end
    end
  end

  describe "#subject_places" do
    subject { record.subject_places }

    context "with non-structured place subjects" do
      let(:subjects) do
        [
          {"type" => "place", "value" => "California"}
        ]
      end

      it "returns the value as a string" do
        is_expected.to eq(["California"])
      end
    end

    context "with structured place subjects" do
      let(:subjects) do
        [
          {
            "structuredValue" => [
              {"value" => "Germany", "type" => "country"},
              {"value" => "Leipzig", "type" => "city"}
            ],
            "type" => "place"
          }
        ]
      end

      it "returns the values separately" do
        is_expected.to eq(["Germany", "Leipzig"])
      end
    end

    context "with nested structured place subjects" do
      let(:subjects) do
        [
          {
            "structuredValue" => [
              {
                "type" => "place",
                "structuredValue" => [
                  {"value" => "Paris", "type" => "city"},
                  {"value" => "France", "type" => "country"}
                ]
              },
              {"value" => "Eiffel Tower"},
              {"value" => "Construction"}
            ],
            "type" => "topic"
          }
        ]
      end

      it "returns the place values separately" do
        is_expected.to eq(["Paris", "France"])
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
        {"type" => "name", "value" => "John Doe"},
        {"type" => "place", "value" => "California"}
      ]
    end
    describe "#subject_all" do
      subject { record.subject_all }

      it "combines all subject facets" do
        is_expected.to eq(["Climate change", "Software Engineer", "John Doe", "The Great Gatsby", "2020", "Fiction", "California"])
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

  describe "#subject_all_display" do
    subject { record.subject_all_display }

    context "with structured subjects" do
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

      it "joins the values with >" do
        is_expected.to eq(["Painters > Italy"])
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

      it "joins the values with >" do
        is_expected.to eq(["Painters > Italy"])
      end
    end

    context "with deeply nested structured subjects of different types" do
      # from druid:kj040zn0537
      let(:subjects) do
        [
          {
            "structuredValue" => [
              {
                "type" => "person",
                "structuredValue" => [
                  {"value" => "duchess d'", "type" => "term of address"},
                  {"value" => "Angoulême, Marie-Thérèse Charlotte de France", "type" => "name"},
                  {"value" => "1778-1851", "type" => "life dates"}
                ]
              },
              {
                "value" => "Emprisonnement",
                "type" => "topic"
              }
            ]
          }
        ]
      end

      it "formats according to type and joins the results with >" do
        is_expected.to eq(["Angoulême, Marie-Thérèse Charlotte de France, duchess d', 1778-1851 > Emprisonnement"])
      end
    end
  end

  describe "#subject_display_data" do
    subject { record.subject_display_data }

    let(:subjects) do
      [
        {
          "structuredValue" => [ # structured; no type
            {"value" => "Painters", "type" => "topic"},
            {"value" => "Italy", "type" => "topic"}
          ]
        },
        {"type" => "genre", "value" => "Science Fiction"},  # ignored; goes in genre
        {"type" => "topic", "value" => "History"},
        {"type" => "map coordinates", "value" => "W 18°--E 51°/N 37°--S 35°"}, # ignored; goes in map data
        {"type" => "classification", "value" => "QA76.73.J38"} # ignored; internal only
      ]
    end

    it "aggregates display data for subjects" do
      is_expected.to contain_exactly(
        be_a(CocinaDisplay::DisplayData).and(have_attributes(
          label: "Subject",
          values: [
            "Painters > Italy",
            "History"
          ]
        ))
      )
    end
  end
end

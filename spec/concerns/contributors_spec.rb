require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:contributors) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "contributor" => contributors
      }
    }.to_json
  end
  let(:record) { described_class.from_json(cocina_json) }
  let(:with_date) { false }

  describe "#main_contributor_name" do
    subject { record.main_contributor_name(with_date: with_date) }

    context "with a primary contributor" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          }
        ]
      end

      it { is_expected.to eq("Doe, John") }
    end

    context "with a primary contributor who is not an author" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "status" => "primary"
          }
        ]
      end

      it { is_expected.to eq("Smith, Jane") }
    end

    context "with contributors with no role" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}]
          },
          {
            "name" => [{"value" => "Smith, Jane"}]
          }
        ]
      end

      it "uses the first contributor as the main author" do
        is_expected.to eq("Doe, John")
      end
    end

    context "with multiple contributors, none primary" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}]
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "creator"}]
          }
        ]
      end

      it "uses the first contributor" do
        is_expected.to eq("Doe, John")
      end
    end

    context "with life dates" do
      let(:with_date) { true }
      let(:contributors) do
        [
          {
            "name" => [
              {"structuredValue" => [
                {"value" => "Doe, John"},
                {"value" => "1970-2020", "type" => "life dates"}
              ]}
            ],
            "role" => [{"value" => "author"}]
          }
        ]
      end

      it { is_expected.to eq("Doe, John, 1970-2020") }
    end
  end

  describe "#additional_contributor_names" do
    subject { record.additional_contributor_names(with_date: with_date) }

    context "with a primary contributor and other contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}]
          }
        ]
      end

      it "returns additional authors excluding the primary one" do
        is_expected.to eq(["Smith, Jane"])
      end
    end
  end

  describe "#person_contributor_names" do
    subject { record.person_contributor_names(with_date: with_date) }

    context "with person authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person",
            "status" => "primary"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["Doe, John", "Smith, Jane"]) }
    end

    context "with no person authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "author"}],
            "type" => "organization"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#impersonal_contributor_names" do
    subject { record.impersonal_contributor_names }

    context "with impersonal contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "author"}],
            "type" => "organization"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Corp"]) }
    end

    context "with no impersonal authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#organization_contributor_names" do
    subject { record.organization_contributor_names }

    context "with organization contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "author"}],
            "type" => "organization"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Corp"]) }
    end

    context "with no organization authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#conference_contributor_names" do
    subject { record.conference_contributor_names }

    context "with conference contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Conference"}],
            "role" => [{"value" => "author"}],
            "type" => "conference"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Conference"]) }
    end

    context "with no conference authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#sort_contributor_name" do
    subject { record.sort_contributor_name }

    context "with a main contributor" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          }
        ]
      end

      it "removes punctuation and adds sort title" do
        is_expected.to eq("Doe John \u{10FFFF}")
      end
    end

    context "with no main author and no title" do
      let(:contributors) { [] }

      it { is_expected.to eq("\u{10FFFF} \u{10FFFF}") } # Unicode replacement character for missing value
    end

    context "with a main contributor and a title" do
      let(:cocina_json) do
        {
          "description" => {
            "contributor" => [
              {
                "name" => [{"value" => "Doe, John"}],
                "role" => [{"value" => "author"}],
                "status" => "primary"
              }
            ],
            "title" => [{"value" => "Sample Title"}]
          }
        }.to_json
      end

      it "appends the title for disambiguation" do
        is_expected.to eq("Doe John Sample Title")
      end
    end
  end

  describe "#contributor_names_by_role" do
    subject { record.contributor_names_by_role(with_date: with_date) }

    context "with multiple contributors and roles and with date" do
      let(:with_date) { true }
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          },
          # from druid:kj040zn0537
          {
            "type" => "person",
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Lasinio, Carlo", "type" => "name"},
                  {"value" => "1759-1838", "type" => "life dates"}
                ]
              }
            ],
            "status" => "primary",
            "role" => [
              {"code" => "egr", "source" => {"code" => "marcrelator"}}
            ]
          }
        ]
      end

      it "groups contributors by their roles" do
        is_expected.to eq({
          "author" => ["Doe, John"],
          "editor" => ["Smith, Jane"],
          "publisher" => ["ACME Corp"],
          "engraver" => ["Lasinio, Carlo, 1759-1838"]
        })
      end
    end

    context "with no contributors" do
      let(:contributors) { [] }

      it { is_expected.to be_empty }
    end

    context "with contributors that have empty names" do
      let(:contributors) do
        [
          {
            "name" => [{}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "John Smith"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          }
        ]
      end

      it "returns only names with values" do
        is_expected.to eq({
          "editor" => ["John Smith"]
        })
      end
    end
  end

  describe "#publisher_names" do
    subject { record.publisher_names }

    context "with publisher contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Publishing"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Publishing"]) }
    end

    context "with no publisher contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end

    context "with publication event contributors" do
      let(:cocina_json) do
        {
          "description" => {
            "event" => [
              {
                "type" => "publication",
                "contributor" => [
                  {
                    "name" => [{"value" => "Chronicle Books"}],
                    "role" => [{"value" => "publisher"}]
                  }
                ]
              }
            ]
          }
        }.to_json
      end

      it "returns the publisher from the event" do
        is_expected.to eq(["Chronicle Books"])
      end
    end
  end
end
